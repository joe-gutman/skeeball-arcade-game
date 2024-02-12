//player settings
key player;

//aim settings
integer aim_mode = 1; // aim_mode 1 = Move Left/Right; aim_mode 2 = Rot Left/Right
integer aim_rot = 0;
integer aim_rotincrement = 1;
integer aim_rotlimit = 20; //in degrees
float aim_pos = 0;
float aim_posincrement = .05;
float aim_poslimit; // based off of arrow size and lane size


//ball settings
string ball_name = "[BBS] Skeeball Ball";
list ball_keys;
integer ball_current = 0;
integer ball_listenhandle;
integer ball_life = 10; // parameter that will be passed to ball to tell ball how long to stay rezzed, in seconds.
integer control_back_count = 0;
integer control_fwd_count = 0;
float ball_speed = 0; 
float ball_speedincrement = .25;
float ball_speedmax = 12;
float ball_speedflip = 0; //0 = inactive, 1 = active not flipped, 2 = active flipped.
float ball_mass = 1.25;
vector ball_rezpos = < 0, 0, .1>; // The distance to adjust the ball rez position from the aim arrow. 
vector ball_direction = <0.0,1.0,0.0>; // apply velocity in x, y, or z heading.
float ball_timerspeed = .01;

//arrow prim settings
integer arrow_link;
string arrow_name = "arrow";
key arrow_texture = "663649e6-2b6b-8c6d-e7fc-a4917deaaf97";
vector arrow_scale;
vector arrow_startpos;
vector arrow_pos;
float arrow_poslimit;
rotation arrow_rot;
integer arrow_rotoffset = 90;
float arrow_textincrement;
float arrow_currenttextpos = 0;

//mode indicator settings
integer mode_link;
integer mode_face = 0;
string mode_name = "mode";
key mode_rottexture = "a1571152-0a05-2fc4-763b-505b806f1307";
key mode_movetexture = "faf75693-c4c2-911d-8bc7-c3a07cdce016";
key mode_rottextureleft = "a1571152-0a05-2fc4-763b-505b806f1307";
key mode_movetextureleft = "faf75693-c4c2-911d-8bc7-c3a07cdce016";
key mode_rottextureright = "a1571152-0a05-2fc4-763b-505b806f1307";
key mode_movetextureright = "faf75693-c4c2-911d-8bc7-c3a07cdce016";

//ball path guide
integer guide_link;
string guide_name = "guide";
vector guide_scale;
integer guide_maxlength = 5;
vector base_scale;

ball_roll()
{
    llSetTimerEvent(0);

    arrow_currenttextpos = 0;
    llSetLinkPrimitiveParamsFast(arrow_link, [PRIM_TEXTURE,  0, arrow_texture, <1, 1, 0>, <0, 0, 0>, 0.0]);


    arrow_rot = llEuler2Rot(<0,0,(aim_rot*aim_rotincrement)>*DEG_TO_RAD);
    arrow_pos = < (aim_pos*aim_posincrement), arrow_startpos.y, arrow_startpos.z>;

    vector velocity = (ball_mass * ball_speed * ball_direction)*(llGetRot()*arrow_rot);
    vector velocity_max = (ball_mass * ball_speedmax * ball_direction)*(llGetRot()*arrow_rot);
    vector position = llGetPos() + ((arrow_pos + ball_rezpos) * llGetRot());

    llRegionSayTo((key)llList2String(ball_keys, ball_current), Key2Chan((key)llList2String(ball_keys, ball_current)), llList2CSV([position, velocity, (integer)llVecMag(velocity_max)]));
    ++ball_current;
    //llOwnerSay((string)ball_current);
    //llOwnerSay("ball thrown");
    //llRezObject(ball_name, position, velocity, ZERO_ROTATION, (integer)llVecMag(velocity_max));  
    ball_speed = 0;

    llMessageLinked(LINK_ROOT, 0, "ball thrown", NULL_KEY);
    llMessageLinked(LINK_ROOT, 0, "rez ball", NULL_KEY);
    llSetTimerEvent(0);
}

aim_move()
{
    arrow_startpos = llList2Vector(llGetLinkPrimitiveParams(arrow_link, [PRIM_POS_LOCAL]), 0);
    arrow_rot = llEuler2Rot(<0,0,(aim_rot*aim_rotincrement)-arrow_rotoffset>*DEG_TO_RAD);
    arrow_pos = < (aim_pos*aim_posincrement), arrow_startpos.y, arrow_startpos.z>;
    llSetLinkPrimitiveParamsFast(arrow_link, [PRIM_ROT_LOCAL, arrow_rot, PRIM_POS_LOCAL, arrow_pos]);
    llSetLinkPrimitiveParamsFast(guide_link, [PRIM_POS_LOCAL, arrow_pos]);
    llSetLinkPrimitiveParamsFast(mode_link, [PRIM_POS_LOCAL, arrow_pos]);

    arrow_rot = llEuler2Rot(<0,0,(aim_rot*aim_rotincrement)>*DEG_TO_RAD);
    llSetLinkPrimitiveParamsFast(guide_link, [PRIM_ROT_LOCAL, arrow_rot]);

    vector ray_start = llGetPos() + ((arrow_pos + < 0, 0, .05>) * llGetRot()); //arrows adjusted position based on root rotation.
    vector ray_end = ray_start + (< 0, 2.5, .05>*(arrow_rot*llGetRot()));

    //llRezObject("ray_indicator", ray_start, ZERO_VECTOR, ZERO_ROTATION, 0);
    //llRezObject("ray_indicator", ray_end, ZERO_VECTOR, ZERO_ROTATION, 0);
    list results = llCastRay(ray_start, ray_end,[RC_REJECT_TYPES,RC_REJECT_PHYSICAL,RC_DETECT_PHANTOM,TRUE,RC_MAX_HITS,1]);
    key target_uuid = (key)llList2String(results,0);
    vector target_pos = (vector)llList2String(results,1);

    float distance = llVecDist(ray_start, target_pos);
    if (distance < guide_maxlength)
    {
        llSetLinkPrimitiveParamsFast(guide_link, [PRIM_SIZE, <guide_scale.x, distance*2, guide_scale.z>]);    
    }
    else
    {
        llSetLinkPrimitiveParamsFast(guide_link, [PRIM_SIZE, <guide_scale.x, guide_maxlength, guide_scale.z>]);     
    }

    //llOwnerSay((string)aim_pos);
    if (aim_pos <= -aim_poslimit || aim_pos >= aim_poslimit)
    {
        //llOwnerSay("Limit Met");
        aimmode_set();
    }
}

aimmode_set()
{
    if (aim_mode == 1)
    {
        if (aim_pos <= -aim_poslimit)
        {
            llSetLinkPrimitiveParamsFast(mode_link, [PRIM_TEXTURE, mode_face, mode_movetextureright, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
        }
        else if (aim_pos >= aim_poslimit)
        {
            llSetLinkPrimitiveParamsFast(mode_link, [PRIM_TEXTURE, mode_face, mode_movetextureleft, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);  
        }
        else
        {
            llSetLinkPrimitiveParamsFast(mode_link, [PRIM_TEXTURE, mode_face, mode_movetexture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);          
        }
    }
    if (aim_mode == 2)
    {
        if (aim_pos <= -aim_poslimit)
        {
            llSetLinkPrimitiveParamsFast(mode_link, [PRIM_TEXTURE, mode_face, mode_rottextureright, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
        }
        else if (aim_pos >= aim_poslimit)
        {
            llSetLinkPrimitiveParamsFast(mode_link, [PRIM_TEXTURE, mode_face, mode_rottextureleft, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);  
        }
        else
        {
            llSetLinkPrimitiveParamsFast(mode_link, [PRIM_TEXTURE, mode_face, mode_rottexture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);          
        }
    }
}

integer Name2LinkNum(string sName)
{
    integer i;
    integer iPrims;
    //
    if (llGetAttached()) iPrims = llGetNumberOfPrims(); else iPrims = llGetObjectPrimCount(llGetKey());
    for (i = iPrims; i >= 0; i--) if (llList2String(llGetLinkPrimitiveParams(i, [PRIM_NAME]), 0) == sName) return i;
    return -1;
}

integer Key2Chan(key ID) 
{
    return 0x80000000 | (integer)("0x"+(string)ID);
}

default
{
    state_entry()
    {
        llReleaseControls();
        //gather link numbers
        arrow_link = Name2LinkNum(arrow_name);
        mode_link = Name2LinkNum(mode_name);
        guide_link = Name2LinkNum(guide_name);

        //gather aim scale and limits
        arrow_startpos = llList2Vector(llGetLinkPrimitiveParams(arrow_link, [PRIM_POS_LOCAL]), 0);
        base_scale = llGetScale();
        arrow_scale = llList2Vector(llGetLinkPrimitiveParams(arrow_link, [PRIM_SIZE]), 0);
        guide_scale = llList2Vector(llGetLinkPrimitiveParams(guide_link, [PRIM_SIZE]), 0);
        aim_poslimit = llFloor(((base_scale.x - arrow_scale.y)/2)/aim_posincrement);
        //llOwnerSay((string)aim_poslimit);

        ball_speedflip = 0; 

        //reset aimmode
        aim_mode = 1;
        aimmode_set();
    }
    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == 1)    
        {
            player = id;
            ball_keys = llCSV2List(str);
            //llOwnerSay(str);
            state controls;
        }
    }
}

state controls
{
    state_entry()
    {
        llRequestPermissions(player, PERMISSION_TAKE_CONTROLS);
    }
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TAKE_CONTROLS)
        {
            llTakeControls(
                            CONTROL_FWD |
                            CONTROL_BACK |
                            CONTROL_LEFT |
                            CONTROL_RIGHT |
                            CONTROL_ROT_LEFT |
                            CONTROL_ROT_RIGHT |
                            CONTROL_UP |
                            CONTROL_DOWN |
                            CONTROL_LBUTTON |
                            CONTROL_ML_LBUTTON ,
                            TRUE, FALSE);
            llMessageLinked(LINK_THIS, 0, "rez ball", NULL_KEY);  
        }   
        else
        {
            llMessageLinked(LINK_ROOT, 0, "game over", NULL_KEY);    
        } 
    }
    control(key id, integer held, integer pressed)
    {
        llMessageLinked(LINK_ROOT, 0, "activity", NULL_KEY);
        if (CONTROL_FWD & pressed)
        {
            control_fwd_count ++; //triggers twice for one press and lift
            if (control_fwd_count % 2)
            {
                if (aim_mode == 1)
                {
                    aim_mode ++;
                    aimmode_set();
                }
                else 
                {
                    aim_mode --;
                    aimmode_set();
                }
            }
        }
        
        if (aim_mode == 1)
        {
            if (CONTROL_ROT_LEFT & held || CONTROL_LEFT & held)
            {
                if (aim_pos > -aim_poslimit)
                {
                    aim_pos --;
                    aim_move();
                }
            }
            else if (CONTROL_ROT_RIGHT & held || CONTROL_RIGHT & held)
            {
                if (aim_pos < aim_poslimit)
                {
                    aim_pos ++;
                    aim_move();
                }
            }
        }
        else if (aim_mode == 2)
        {
            if (CONTROL_ROT_LEFT & held  || CONTROL_LEFT & held)
            {
                if (aim_rot < aim_rotlimit)
                {
                    aim_rot ++;
                    aim_move();
                }
            }    
            else if (CONTROL_ROT_RIGHT & held || CONTROL_RIGHT & held)
            {
                if (aim_rot > -aim_rotlimit)
                {
                    aim_rot --;
                    aim_move();
                }
            }
        }   

        if (CONTROL_BACK & pressed)
        {
            control_back_count ++;
            if (control_back_count <= 1)
            {
                ball_speedflip = 1;
                llSetTimerEvent(ball_timerspeed);
            }
            else
            {
                control_back_count = 0;
                ball_speedflip = 0;
                ball_roll();
            }
        } 
    }
    link_message(integer sender_num, integer num, string str, key id)
    {
        if (str == "scratch")
        {
            --ball_current;
            //llOwnerSay((string)ball_current);
        }       
    }
    timer()
    {
        if(ball_speedflip == 1)
        {
            ball_speed += ball_speedincrement;
            llSetLinkPrimitiveParamsFast(arrow_link, [PRIM_TEXTURE,  0, arrow_texture, <1, 1, 0>, <arrow_currenttextpos += .5/(ball_speedmax/ball_speedincrement), 0, 0>, 0.0]);
            if (ball_speed >= ball_speedmax)
            {
                ball_speedflip = 2;
            }
        }
        else if (ball_speedflip == 2)
        {
            ball_speed -= ball_speedincrement;
            llSetLinkPrimitiveParamsFast(arrow_link, [PRIM_TEXTURE,  0, arrow_texture, <1, 1, 0>, <arrow_currenttextpos -= .5/(ball_speedmax/ball_speedincrement), 0, 0>, 0.0]);
            if (ball_speed <= 0)
            {
                ball_speedflip = 1;
            } 
        }    
    }
}