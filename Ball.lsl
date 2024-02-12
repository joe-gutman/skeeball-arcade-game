//communication settings
integer say_chan;
integer ball_channel;
integer rezzer_channel;
integer message_sent = FALSE;
integer ball_scratched = FALSE;

//rez settings
key rezzer_key;
list rez_settings;
vector rez_pos;
vector ball_diameter;

//ball settings
float ball_life = 20; //seconds
float velocity_max;

//base settings
list hole_positions_sizes;
integer hole_count = 8;
vector hole_diameter;
float hole_distance;

//timer settings
float timer_count;
float timer_increment = 0.1;

//Sound Settings
float sound_offset = 10;
float ball_rollvolume = 0.5;
list ball_rollsounds = ["e9d3fe2b-6273-942d-d3aa-e7379f86783e","c4c3d21a-9aa7-1a44-f81d-d1a5ca2f893a","56fdadbb-81b6-1b0d-ee50-1823356d208d","203b5318-726a-c376-c174-466c205f85df"];
float ball_hitvolume = 1.0;
list ball_hitsounds = ["a3683340-6d87-89dc-6781-c387eae66ba1", "962b8b98-5e15-f3dd-ddfc-f6cf44909555", "247652e5-d2c5-e5f8-3806-1274f182623a", "19f8b357-889f-c416-7638-99d305c13b4c", "322f10f7-5038-507a-67ea-4b72fef52b34", "2ddba0b8-d98d-17e5-ab67-c70dac1abf2c"];
float ball_holedropvolume = 0.5;
list ball_holedropsounds = ["a3683340-6d87-89dc-6781-c387eae66ba1", "9ac1ceee-f3f8-358e-ee31-5779c2b9d7cc", "092ec2fb-f5dc-1425-2cbd-5df14328cc7b", "229dab71-153d-72f7-0720-729ebc4d4e77", "ae3adf63-94f4-f289-3b68-bb03fe5898c8", "e43fd579-260b-96a9-ecf4-4dd905f75797"];

integer distance_to_hole()
{
    integer i = 0;
    while (i < hole_count)
    {
        hole_distance = llVecDist(llGetPos(), (vector)llList2String(hole_positions_sizes, i));
        //llOwnerSay("hole_distance: " + (string)hole_distance);
        hole_diameter = (vector)llList2String(hole_positions_sizes, i + hole_count);
        if (hole_distance <= (hole_diameter.x + ball_diameter.x)/2)
        {
            //llOwnerSay("hole = " + (string)i + "; hole_min_distance = " + (string)((hole_diameter.x + ball_diameter.x)/2) + "; hole_distance = " + (string)hole_distance);
            return i;
        }
        if (hole_distance > 10)
        {
            llRegionSayTo(rezzer_key, say_chan, "scratch");
            ball_scratch();
        }
        ++i;
    }
    //llOwnerSay("hole_min_distance = " + (string)((ball_diameter.x)/2) + "hole_distance = " + (string)hole_distance);
    return (-1);
}

integer Key2AppChan(key ID) 
{
    return 0x80000000 | (integer)("0x"+(string)ID);
}

ball_rollsound()
{
    float current_velocity = llVecMag(llGetVel());
    //llOwnerSay("current_velocity = " + (string)current_velocity);
    //llOwnerSay("velocity_max = " + (string)velocity_max);
    if (current_velocity > (velocity_max*0) && current_velocity < (velocity_max*.25))
    {
        llStopSound();
        llLoopSound(llList2Key(ball_rollsounds, 0), ball_rollvolume);    
    }
    else if (current_velocity < (velocity_max*.5) && current_velocity >= (velocity_max*.25))
    {
        llStopSound();
        llLoopSound(llList2Key(ball_rollsounds, 1), ball_rollvolume);    
    }
    else if (current_velocity < (velocity_max*.75) && current_velocity >= (velocity_max*.5))
    {
        llStopSound();
        llLoopSound(llList2Key(ball_rollsounds, 0), ball_rollvolume);    
    }
    else if (current_velocity >= (velocity_max*.75))
    {
        llStopSound();
        llLoopSound(llList2Key(ball_rollsounds, 1), ball_rollvolume);    
    }
}

ball_scratch()
{
    llSetTimerEvent(0);
    message_sent == FALSE;
    llTriggerSound(llList2Key(ball_hitsounds, (integer)llFrand(llGetListLength(ball_hitsounds))-1), ball_hitvolume);
    llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
    llSetStatus(STATUS_PHYSICS, FALSE);
    llSetPos(rez_pos);
    ball_scratched = FALSE;   
    llStopSound(); 
    timer_count = 0;
    llSetTimerEvent(0);
    llRegionSayTo(rezzer_key, say_chan, "ball_reset " + (string)llGetKey());
}

default
{
    on_rez(integer start_param)
    {
        //llOwnerSay((string)llGetKey());
        rezzer_key = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);
        rez_pos = llGetPos();
        ball_diameter = llList2Vector(llGetPrimitiveParams([PRIM_SIZE]), 0); 
        say_chan = Key2AppChan(rezzer_key);
        ball_channel = Key2AppChan(llGetKey());
        rezzer_channel = Key2AppChan(rezzer_key);
        llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
        llListen(ball_channel, "", NULL_KEY, "");
        llListen(rezzer_channel, "", NULL_KEY, "");
    }
    listen(integer channel, string name, key id, string message)
    {
        if (llGetListLength(llCSV2List(message)) > 3)
        {
            hole_positions_sizes = llCSV2List(message);
            //llOwnerSay(message);    
        } 
        else if (llGetListLength(llCSV2List(message)) == 3)
        {

            rez_settings = llCSV2List(message);
            //llOwnerSay(llList2CSV(rez_settings));

            integer velocity_max = (integer)llList2String(rez_settings, 2);
            llSetPos((vector)llList2String(rez_settings, 0));
            llSetStatus(STATUS_PHYSICS, TRUE);
            llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
            llApplyImpulse((vector)llList2String(rez_settings, 1)*llGetMass(), FALSE);
            llSetTimerEvent(timer_increment);
        } 
        else if (message == "reset")
        {
            llDie();
        }
        else if (message == "gameover")
        {
            llDie();
        }    
    }
    timer()
    {
        timer_count += timer_increment;
        if (timer_count >= ball_life)
        {
            ball_scratch();
            llRegionSayTo(rezzer_key, say_chan, "scratch " + (string)llGetKey());
        }
        else
        {
            integer hole_number = distance_to_hole();
            if (hole_number != -1 && message_sent == FALSE)
            {
                llRegionSayTo(rezzer_key, rezzer_channel, "hole_"+(string)hole_number + " " + (string)llGetKey());
                llDie();
                //llOwnerSay("hole_"+(string)hole_number + " " + (string)llGetKey());
            } 
        }
    }
    collision_start(integer num_detected)
    {
        llTriggerSound(llList2Key(ball_hitsounds, (integer)llFrand(llGetListLength(ball_hitsounds))-1), ball_hitvolume);
        ball_rollsound();   
        if (llDetectedKey(0) != rezzer_key && llKey2Name(llDetectedKey(0)) != llGetObjectName() && ball_scratched == FALSE)
        {
            ball_scratched == TRUE;
            llRegionSayTo(rezzer_key, say_chan, "scratch " + (string)llGetKey());
            //llOwnerSay("prim scratch");
            ball_scratch();
        }
    }
    land_collision_start( vector pos )
    {
        if (ball_scratched == FALSE)
        {
            ball_scratched == TRUE;
            llRegionSayTo(rezzer_key, say_chan, "scratch " + (string)llGetKey());
            ball_scratch();
        }
    }
}