--[[
LUA MVD script for the extended hifi-q2admin (https://github.com/hifi/q2admin/)

Function:
 Automatically starts recording of Q2Pro Multi View Demos within the Action Quake2 - TNG Mod when match starts.
 It also deletes the mvd-file if match countdown failed.

Fully working initial version by Paul Klumpp, 2012-11-12
Please record your big changes here and increase version number:

1.4: added round_state check, added whether a cvar "q2a_mvd_autorecord" needs to be set so the recording happens runs (for lrcon usage)
1.3: added "exec_script_on_system_after_recording" for config.lua. BE CAREFUL with those shellscripts!
1.2: Checks for (Action Quake 2 and sv_mvd_enable != 0). And added useful mvd defaults for scoreboard
1.1: Even works on aq2-tng public teamplay mode now
1.0: All working on aq2-tng matchmode
0.9: Last Debug
    
config.lua example, with all options:
------------------------------
plugins = {
    some_other_plugin = {
        blah = "blah"
    },
    mvd = {
        mvd_webby = "http://mvd2.quadaver.org",
        exec_script_on_system_after_recording = "/home/gameservers/quake2/plugins/woot.sh",
        needs_cvar_q2a_mvd_autorecord = false
    }
}
------------------------------
!! Notice the "," in front of mvd = {
    
--]]

local game = gi.cvar("game", "").string
local sv_mvd_enable = gi.cvar("sv_mvd_enable", "").string

if game ~= "action" or sv_mvd_enable == "0" then
    gi.dprintf("mvd.lua WARNING: This script only loads when game is 'action' and when sv_mvd_enable is '1' or '2'!\n")
    return 0
end
-- if we came to here, it's action!

local version = "1.4hau"
gi.AddCommandString("sets q2a_mvd "..version.."\n")

local mvd_webby -- configure this one in the config.lua
local exec_script_on_system_after_recording -- configure this one in the config.lua
local needs_cvar_q2a_mvd_autorecord -- configure this one in the config.lua


-- state vars
local teams_ready = {}
local mvd_records = false
local started_on_round_state = ""
local mvd_pathfile = ""
local mvd_file = ""


---- small helper functions follow: ----

function file_exists(fname)
    local f=io.open(fname,"r")
    if f~=nil then 
        io.close(f) 
        return true 
    else 
        return false 
    end
end


function string_strip(badstring)
    goodstring = badstring
    goodstring = string.gsub(goodstring, "%W", "")
    return goodstring
end


function reset_ready_state()
    for k in pairs (teams_ready) do
        teams_ready[k] = nil
    end
end


function get_round_state()
    local teamplay = gi.cvar("teamplay", "").string
    if teamplay == "1" then
        local cvar_t1 = gi.cvar("t1", "").string
        local cvar_t2 = gi.cvar("t2", "").string
        local cvar_t2 = gi.cvar("t3", "").string
        local rstate = ""..t1.." "..t2.." "..t3..""
        return rstate
    end
    return 0
end


---- big helper functions follow: ----

function mvd_start_recording()
    -- if teamplay == 1 then save round state .. for later usage - 
    -- this is to know if record stopping also can delete the newly recorded mvd, because the rounds did not happen.
    started_on_round_state = get_round_state()

    -- build filename
    local now = os.date("%Y-%m-%d_%H%M%S")
    local mapname = gi.cvar("mapname", "").string

    local filename = now
    for k,v in pairs(teams_ready) do 
        filename = filename .. "_" .. v
        --gi.AddCommandString("say starting team: "..v.."\n")
    end
    filename = filename.."_"..mapname
    gi.AddCommandString("mvdrecord -z "..filename.."\n")

    mvd_file = filename..".mvd2.gz"
    mvd_pathfile = game.."/demos/"..mvd_file

    mvd_records = true

    local hostname = gi.cvar("hostname", "").string

    gi.AddCommandString("say '"..hostname.."' MVD2 recording started: "..mvd_file.."\n")

end

function mvd_stop_and_delete()
    
    local current_round_state = get_round_state()
    
    if current_round_state == started_on_round_state then
        if mvd_records == true then
            gi.AddCommandString("mvdstop\n")
            mvd_records = false
            -- if file exists in game dir, delete it
            --$game demos/lala.mvd2.gz
            if file_exists(mvd_pathfile) then
                if os.remove(mvd_pathfile) then
                    gi.AddCommandString("say Deleted the MVD2: "..mvd_pathfile.."\n")
                else
                    gi.AddCommandString("say Problems deleting MVD2: "..mvd_pathfile.."\n")
                end
            end
            mvd_pathfile = ""
            mvd_file = ""
        end
    else
        if mvd_records == true then
            gi.AddCommandString("say Be quick to ready up again! MVD2 is still recording!\n")
        end
    end
    
end


function mvd_stop()
    if mvd_records == true then
        gi.AddCommandString("mvdstop\n")
        mvd_records = false
        -- if file exists in game dir, advertise it:
        if file_exists(mvd_pathfile) then
            --$game demos/lala.mvd2.gz
            if mvd_webby ~= nil then
                gi.AddCommandString("say Download the MVD2("..mvd_file..") on "..mvd_webby.."\n")
            else
                gi.AddCommandString("say Download the MVD2: "..mvd_file.."\n")
            end
            if exec_script_on_system_after_recording ~= nil then
                gi.dprintf('mvd.lua mvd_stop(): os.execute '..exec_script_on_system_after_recording..' "'..game..'" "'..mvd_file..'"\n')
                local returnstuff = os.execute(exec_script_on_system_after_recording..' "'..game..'" "'..mvd_file..'"')
                gi.dprintf('mvd.lua mvd_stop(): os.execute returns: '..returnstuff..'\n')
            end
            
        end
        mvd_pathfile = ""
        mvd_file = ""
    end
end


---- q2admin hook functions follow: ----

function q2a_load(config)
    gi.dprintf("mvd.lua q2a_load(): "..version.." for Action Quake 2 loaded.\n")
    
    mvd_webby = config.mvd_webby
    exec_script_on_system_after_recording = config.exec_script_on_system_after_recording
    
    if mvd_webby == nil then
        gi.dprintf("mvd.lua q2a_load(): You may define 'mvd_webby' in the config.lua file.\n")
        
        -- safe default:
        mvd_webby = nil
    end
    
    if exec_script_on_system_after_recording == nil then
        gi.dprintf("mvd.lua q2a_load(): You may define 'exec_script_on_system_after_recording' in the config.lua file.\n")
        
        -- safe default:
        exec_script_on_system_after_recording = nil
    end
    
    if needs_cvar_q2a_mvd_autorecord == nil then
        gi.dprintf("mvd.lua q2a_load(): You may define 'needs_cvar_q2a_mvd_autorecord' in the config.lua file.\n")
        
        needs_cvar_q2a_mvd_autorecord = false
    end

    -- set some working defaults (workarounds) if game is action...
    if game == "action" then
        gi.AddCommandString('set sv_mvd_nomsg 0\n')
        gi.AddCommandString('set sv_mvd_begincmd "putaway; h_cycle;"\n')
        gi.AddCommandString('set sv_mvd_scorecmd "h_cycle;"\n')
        gi.AddCommandString('alias h_cycle "h_cycle_sb; h_cycle_sb; h_cycle_sb; h_cycle_sb; h_cycle_sb;"\n')
        gi.AddCommandString('alias h_cycle_sb "wait; help; wait 75; help; wait 100; putaway;"\n')
        gi.AddCommandString('set mvd_default_map wfall\n')
    end
end


function LevelChanged(level)
    gi.dprintf("mvd.lua LevelChanged(): it has been changed to %s\n", level)
    -- reset teams ready state
    reset_ready_state()
    
    -- if mvd is recording, stop mvd recording and advertise
    mvd_stop()
    
end


function LogMessage(msg)
    
    --debug of all incoming msg:
    --gi.AddCommandString("say "..msg.."\n")
    
    local team_ready = string.match(msg, "(.+) is ready to play!")
    if team_ready ~= nil then
        -- strip whitespace and bad chars
        team_ready = string_strip(team_ready)
        
        --gi.AddCommandString("say adding team: "..team_ready.."\n")
        
        table.insert(teams_ready,team_ready)
        
        return true
    end
    
    local team_notready = string.match(msg, "(.+) is no longer ready to play!")
    if team_notready ~= nil then
        -- strip whitespace and bad chars
        team_notready = string_strip(team_notready)
        
        for k,v in pairs(teams_ready) do
            if v == team_notready then
                table.remove(teams_ready, k)
            end
        end
        
        return true
    end
    
    local match = string.match(msg, "The round will begin in 20 seconds!")
    if match ~= nil then
        -- if mvd not recording then start mvd record
        if mvd_records == false then
            
            if needs_cvar_q2a_mvd_autorecord == true then
                local q2a_mvd_autorecord = gi.cvar("q2a_mvd_autorecord", "").string
                if q2a_mvd_autorecord ~= nil and q2a_mvd_autorecord ~= "0" then 
                    mvd_start_recording()
                end
            else
                mvd_start_recording()
            end
            
        end
        
        return true
    end

    local match = string.match(msg, "Both Teams Must Be Ready!")
    if match ~= nil then
        -- if mvd is currently recording and t1, t2 == 0, then stop mvd recording and delete file
        mvd_stop_and_delete()

        return true
    end
    
    -- this message can't be catched by LogMessage .. .:(
    --local match = string.match(msg, "Recording local MVD to (.+)")
    --if match ~= nil then
    --    mvd_pathfile = match
    --    mvd_records = true
    --    gi.AddCommandString("say MVD2 recording started: "..mvd_pathfile.."\n")
    --    return true
    --end
    
    local match = string.match(msg, "Scores and time was resetted by request of captains")
    if match ~= nil then
        -- reset teams ready state
        reset_ready_state()
        
        -- if mvd is currently recording and t1, t2 == 0, then stop mvd recording and delete file
        mvd_stop_and_delete()
        
        return true
    end
    
    local match = string.match(msg, "Match is over, waiting for next map, please vote a new one..")
    if match ~= nil then
        -- reset teams ready state
        reset_ready_state()
        
        -- if mvd is recording, stop mvd recording and advertise
        mvd_stop()
        
        return true
    end
    
    local match = string.match(msg, "Game ending at:.+")
    if match ~= nil then
        -- reset teams ready state
        reset_ready_state()
        
        -- if mvd is recording, stop mvd recording and advertise
        mvd_stop()
        
        return true
    end

end -- of LogMessage


-- The round will begin in 20 seconds!
   -- if mvd is not recording then start mvd record

-- Both Teams Must Be Ready!
   -- if mvd is currently recording and t1, t2 == 0, then stop mvd recording and delete file

-- Recording local MVD to demos/1352750130_Team#2_Team#1.mvd2.gz
   -- save full filename
   -- set mvd_records state to true

-- Scores and time was resetted by request of captains
   -- if mvd is currently recording, then stop mvd recording and delete file

-- Match is over, waiting for next map, please vote a new one..
   -- if mvd is currently recording, then stop mvd recording (and keep file) and advertise!
        
