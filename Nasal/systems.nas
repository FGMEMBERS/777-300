# 777-300 systems
#Syd Adams
#

var SndOut = props.globals.getNode("/sim/sound/Ovolume",1);
var chronometer = aircraft.timer.new("/instrumentation/clock/ET-sec",1);
var fuel_density =0;
aircraft.livery.init("Aircraft/777-300/Models/Liveries");
#Wiper=[];

#EFIS specific class
# ie: var efis = EFIS.new("instrumentation/EFIS");
var EFIS = {
    new : func(prop1){
        m = { parents : [EFIS]};
        m.radio_list=["instrumentation/comm/frequencies","instrumentation/comm[1]/frequencies","instrumentation/nav/frequencies","instrumentation/nav[1]/frequencies"];
        m.mfd_mode_list=["APP","VOR","MAP","PLAN"];

        m.efis = props.globals.initNode(prop1);
        m.mfd = m.efis.initNode("mfd");
        m.pfd = m.efis.initNode("pfd");
        m.eicas = m.efis.initNode("eicas");
        m.mfd_mode_num = m.mfd.initNode("mode-num",2,"INT");
        m.mfd_display_mode = m.mfd.initNode("display-mode",m.mfd_mode_list[2]);
        m.kpa_mode = m.efis.initNode("inputs/kpa-mode",0,"BOOL");
        m.kpa_output = m.efis.initNode("inhg-kpa",29.92);
        m.temp = m.efis.initNode("fixed-temp",0);
        m.alt_meters = m.efis.initNode("inputs/alt-meters",0,"BOOL");
        m.fpv = m.efis.initNode("inputs/fpv",0,"BOOL");
        m.nd_centered = m.efis.initNode("inputs/nd-centered",0,"BOOL");
        m.mins_mode = m.efis.initNode("inputs/minimums-mode",0,"BOOL");
        m.mins_mode_txt = m.efis.initNode("minimums-mode-text","RADIO","STRING");
        m.minimums = m.efis.initNode("minimums",250,"INT");
        m.mk_minimums = props.globals.getNode("instrumentation/mk-viii/inputs/arinc429/decision-height");
        m.wxr = m.efis.initNode("inputs/wxr",0,"BOOL");
        m.range = m.efis.initNode("inputs/range",0);
        m.sta = m.efis.initNode("inputs/sta",0,"BOOL");
        m.wpt = m.efis.initNode("inputs/wpt",0,"BOOL");
        m.arpt = m.efis.initNode("inputs/arpt",0,"BOOL");
        m.data = m.efis.initNode("inputs/data",0,"BOOL");
        m.pos = m.efis.initNode("inputs/pos",0,"BOOL");
        m.terr = m.efis.initNode("inputs/terr",0,"BOOL");
        m.rh_vor_adf = m.efis.initNode("inputs/rh-vor-adf",0,"INT");
        m.lh_vor_adf = m.efis.initNode("inputs/lh-vor-adf",0,"INT");

        m.radio = m.efis.getNode("radio-mode",1);
        m.radio.setIntValue(0);
        m.radio_selected = m.efis.getNode("radio-selected",1);
        m.radio_selected.setDoubleValue(getprop("instrumentation/comm/frequencies/selected-mhz"));
        m.radio_standby = m.efis.getNode("radio-standby",1);
        m.radio_standby.setDoubleValue(getprop("instrumentation/comm/frequencies/standby-mhz"));

        m.kpaL = setlistener("instrumentation/altimeter/setting-inhg", func m.calc_kpa());

        m.eicas_msg_alert   = m.eicas.initNode("msg/alert"," ","STRING");
        m.eicas_msg_caution = m.eicas.initNode("msg/caution"," ","STRING");
        m.eicas_msg_info    = m.eicas.initNode("msg/info"," ","STRING");

    return m;
    },
#### convert inhg to kpa ####
    calc_kpa : func{
        var kp = getprop("instrumentation/altimeter/setting-inhg");
        kp= kp * 33.8637526;
        me.kpa_output.setValue(kp);
        },
#### update temperature display ####
    update_temp : func{
        var tmp = getprop("/environment/temperature-degc");
        if(tmp < 0.00){
            tmp = -1 * tmp;
        }
        me.temp.setValue(tmp);
    },
#### swap radio freq ####
    swap_freq : func(){
        var tmpsel = me.radio_selected.getValue();
        var tmpstb = me.radio_standby.getValue();
        me.radio_selected.setValue(tmpstb);
        me.radio_standby.setValue(tmpsel);
        me.update_frequencies();
    },
#### copy efis freq to radios ####
    update_frequencies : func(){
        var fq = me.radio.getValue();
        setprop(me.radio_list[fq]~"/selected-mhz",me.radio_selected.getValue());
        setprop(me.radio_list[fq]~"/standby-mhz",me.radio_standby.getValue());
    },
#### modify efis radio standby freq ####
    set_freq : func(fdr){
        var rd = me.radio.getValue();
        var frq =me.radio_standby.getValue();
        var frq_step =0;
        if(rd >=2){
            if(fdr ==1)frq_step = 0.05;
            if(fdr ==-1)frq_step = -0.05;
            if(fdr ==10)frq_step = 1.0;
            if(fdr ==-10)frq_step = -1.0;
            frq += frq_step;
            if(frq > 118.000)frq -= 10.000;
            if(frq<108.000) frq += 10.000;
        }else{
            if(fdr ==1)frq_step = 0.025;
            if(fdr ==-1)frq_step = -0.025;
            if(fdr ==10)frq_step = 1.0;
            if(fdr ==-10)frq_step = -1.0;
            frq += frq_step;
            if(frq > 136.000)frq -= 18.000;
            if(frq<118.000) frq += 18.000;
        }
        me.radio_standby.setValue(frq);
        me.update_frequencies();
    },

    set_radio_mode : func(rm){
        me.radio.setIntValue(rm);
        me.radio_selected.setDoubleValue(getprop(me.radio_list[rm]~"/selected-mhz"));
        me.radio_standby.setDoubleValue(getprop(me.radio_list[rm]~"/standby-mhz"));
    },
######### Controller buttons ##########
    ctl_func : func(md,val){
        controls.click(3);
        if(md=="range")
        {
            var rng =getprop("instrumentation/radar/range");
            if(val ==1){
                rng =rng * 2;
                if(rng > 640) rng = 640;
            }elsif(val =-1){
                rng =rng / 2;
                if(rng < 10) rng = 10;
            }
            setprop("instrumentation/radar/range",rng);
            me.range.setValue(rng);
        }
        elsif(md=="tfc")
        {
            var pos =getprop("instrumentation/radar/switch");
            if(pos == "on"){
                pos = "off";
                
            }else{
                pos="on";
            }
            setprop("instrumentation/radar/switch",pos);
        }
        elsif(md=="dh")
        {
            var num =me.minimums.getValue();
            if(val==0){
                num=250;
            }else{
                num+=val;
                if(num<0)num=0;
                if(num>1000)num=1000;
            }
            me.minimums.setValue(num);
            me.mk_minimums.setValue(num);
        }
        elsif(md=="mins")
        {
            mode = me.mins_mode.getValue();
            me.mins_mode.setValue(1-mode);
            if (mode)
                me.mins_mode_txt.setValue("RADIO");
            else
                me.mins_mode_txt.setValue("BARO");
        }
        elsif(md=="display")
        {
            var num =me.mfd_mode_num.getValue();
            num+=val;
            if(num<0)num=0;
            if(num>3)num=3;
            me.mfd_mode_num.setValue(num);
            me.mfd_display_mode.setValue(me.mfd_mode_list[num]);
        }
        elsif(md=="terr")
        {
            var num =me.terr.getValue();
            num=1-num;
            me.terr.setValue(num);
        }
        elsif(md=="arpt")
        {
            var num =me.arpt.getValue();
            num=1-num;
            me.arpt.setValue(num);
        }
        elsif(md=="wpt")
        {
            var num =me.wpt.getValue();
            num=1-num;
            me.wpt.setValue(num);
        }
        elsif(md=="sta")
        {
            var num =me.sta.getValue();
            num=1-num;
            me.sta.setValue(num);
        }
        elsif(md=="wxr")
        {
            var num =me.wxr.getValue();
            num=1-num;
            me.wxr.setValue(num);
        }
        elsif(md=="rhvor")
        {
            var num =me.rh_vor_adf.getValue();
            num+=val;
            if(num>1)num=1;
            if(num<-1)num=-1;
            me.rh_vor_adf.setValue(num);
        }
        elsif(md=="lhvor")
        {
            var num =me.lh_vor_adf.getValue();
            num+=val;
            if(num>1)num=1;
            if(num<-1)num=-1;
            me.lh_vor_adf.setValue(num);
        }
        elsif(md=="center")
        {
            var num =me.nd_centered.getValue();
            var fnt=[5,8];
            num = 1 - num;
            me.nd_centered.setValue(num);
            setprop("instrumentation/radar/font/size",fnt[num]);
        }
    },	
#### update EICAS messages ####
    update_eicas : func(alertmsgs,cautionmsgs,infomsgs) {
        var msg="";
        var spacer="";
        for(var i=0; i<size(alertmsgs); i+=1)
        {
            msg = msg ~ alertmsgs[i] ~ "\n";
            spacer = spacer ~ "\n";
        }
        me.eicas_msg_alert.setValue(msg);
        msg=spacer;
        for(var i=0; i<size(cautionmsgs); i+=1)
        {
            msg = msg ~ cautionmsgs[i] ~ "\n";
            spacer = spacer ~ "\n";
        }
        me.eicas_msg_caution.setValue(msg);
        msg=spacer;
        for(var i=0; i<size(infomsgs); i+=1)
        {
            msg = msg ~ infomsgs[i] ~ "\n";
        }
        me.eicas_msg_info.setValue(msg);
    },
};
##############################################
##############################################
#Engine control class
# ie: var Eng = Engine.new(engine number);
var Engine = {
    new : func(eng_num){
        m = { parents : [Engine]};
        m.fdensity = getprop("consumables/fuel/tank/density-ppg");
        if(m.fdensity ==nil)m.fdensity=6.72;
        m.eng = props.globals.getNode("engines/engine["~eng_num~"]",1);
        m.running = m.eng.getNode("running",1);
        m.running.setBoolValue(0);
        m.n1 = m.eng.getNode("n1",1);
        m.n2 = m.eng.getNode("n2",1);
        m.rpm = m.eng.getNode("rpm",1);
        m.rpm.setDoubleValue(0);
		m.rpm2 = m.eng.getNode("rpm2",1);
        m.rpm2.setDoubleValue(0);
        m.throttle_lever = props.globals.getNode("controls/engines/engine["~eng_num~"]/throttle-lever",1);
        m.throttle_lever.setDoubleValue(0);
        m.throttle = props.globals.getNode("controls/engines/engine["~eng_num~"]/throttle",1);
        m.throttle.setDoubleValue(0);
        m.cutoff = props.globals.getNode("controls/engines/engine["~eng_num~"]/cutoff",1);
        m.cutoff.setBoolValue(1);
        m.cutoff_lever = props.globals.getNode("controls/engines/engine["~eng_num~"]/cutoff_lever",1);
        m.cutoff_lever.setBoolValue(1);				
        m.fuel_out = props.globals.getNode("engines/engine["~eng_num~"]/out-of-fuel",1);
        m.fuel_out.setBoolValue(0);
        m.starter = props.globals.getNode("controls/engines/engine["~eng_num~"]/starter",1);
        m.fuel_pph=m.eng.getNode("fuel-flow_pph",1);
        m.fuel_pph.setDoubleValue(0);
        m.fuel_gph=m.eng.getNode("fuel-flow-gph",1);
        m.hpump=props.globals.getNode("systems/hydraulics/pump-psi["~eng_num~"]",1);
        m.hpump.setDoubleValue(0);
    return m;
    },
#### update ####
    update : func{
        if(me.fuel_out.getBoolValue())me.cutoff.setBoolValue(1);
        if(!me.cutoff.getBoolValue()){
        me.rpm.setValue(me.n1.getValue());
		me.rpm2.setValue(me.n2.getValue());
        me.throttle_lever.setValue(me.throttle.getValue());
        }else{
            me.throttle_lever.setValue(0);
            if(me.starter.getBoolValue()){
                me.spool_up();
            }else{
                var tmprpm = me.rpm.getValue();
				var tmprpm2 = me.rpm2.getValue();
                if(tmprpm > 0.0){
                    tmprpm -= getprop("sim/time/delta-realtime-sec") * 0.5;
                    me.rpm.setValue(tmprpm);
                }
                if(tmprpm2 > 0.0){
                    tmprpm2 -= getprop("sim/time/delta-realtime-sec") * 1.5;
                    me.rpm2.setValue(tmprpm2);
                }				
            }
        }
    me.fuel_pph.setValue(me.fuel_gph.getValue()*me.fdensity);
    var hpsi =me.rpm.getValue();
    if(hpsi>60)hpsi = 60;
    me.hpump.setValue(hpsi);
    },

    spool_up : func{
        if(me.rpm.getValue()>20.8 and me.rpm2.getValue()>68.2){	
        return;
        }else{
            var tmprpm = me.rpm.getValue();
			var tmprpm2 = me.rpm2.getValue();
			if(me.rpm.getValue()<=20.8){
            tmprpm += getprop("sim/time/delta-realtime-sec") * 0.5;
            me.rpm.setValue(tmprpm);
			}
			if(me.rpm2.getValue()<=68.4){
			tmprpm2 += getprop("sim/time/delta-realtime-sec") * 1.5;
			me.rpm2.setValue(tmprpm2);
			}			
        }
    },

};
##########################
#usage :     var wiper = Wiper.new(wiper property , wiper power source (separate from on off switch));
#
#    var wiper = Wiper.new("controls/electric/wipers","systems/electrical/left-bus");

var Wiper = {
    new : func {
        m = { parents : [Wiper] };
        m.direction = 0;
        m.delay_count = 0;
        m.spd_factor = 0;
        m.node = props.globals.getNode(arg[0],1);
        m.power = props.globals.getNode(arg[1],1);
        if(m.power.getValue()==nil)m.power.setDoubleValue(0);
        m.spd = m.node.getNode("arc-sec",1);
        if(m.spd.getValue()==nil)m.spd.setDoubleValue(0.005);
        m.delay = m.node.getNode("delay-sec",1);
        if(m.delay.getValue()==nil)m.delay.setDoubleValue(2);
        m.position = m.node.getNode("degrees", 1);
        m.position.setDoubleValue(0);
        m.switch = m.node.getNode("speed", 1);
        if (m.switch.getValue() == nil)m.switch.setDoubleValue(0);
        return m;
    },
    active: func{
    if(me.power.getValue()<=5)return;
	if(me.spd.getValue()==0){
	me.position.setValue(0);
	return;
	}
    var spd_factor = 1/me.spd.getValue();
    var pos = me.position.getValue();
    if(!me.switch.getValue()==1){
        if(pos <= 1.000)return;
        }
    if(pos >=90.000){
        me.direction=-1;
        }elsif(pos <=1.000){
        me.direction=0;
        me.delay_count+=getprop("/sim/time/delta-sec");
        if(me.delay_count >= me.delay.getValue()){
            me.delay_count=0;
            me.direction=1;
            }
        }
    var wiper_time = spd_factor*getprop("/sim/time/delta-sec");
    pos +=(wiper_time * me.direction);
    me.position.setValue(pos);
    }
};
#####################

var Efis = EFIS.new("instrumentation/efis");
var LHeng=Engine.new(0);
var RHeng=Engine.new(1);
var wiper1 = Wiper.new("aaa/lwiper","systems/electrical/left-bus");
setprop("/aaa/lwiper/delay-sec", 2);
var wiper2 = Wiper.new("aaa/rwiper","systems/electrical/left-bus");
setprop("/aaa/rwiper/delay-sec", 2);

setlistener("/sim/signals/fdm-initialized", func {
    SndOut.setDoubleValue(0.15);
    chronometer.stop();
    props.globals.initNode("/instrumentation/clock/ET-display",0,"INT");
    props.globals.initNode("/instrumentation/clock/time-display",0,"INT");
    props.globals.initNode("/instrumentation/clock/time-knob",0,"INT");
    props.globals.initNode("/instrumentation/clock/et-knob",0,"INT");
    props.globals.initNode("/instrumentation/clock/set-knob",0,"INT");
#    setprop("/instrumentation/groundradar/id",getprop("sim/tower/airport-id"));
    Shutdown();
    settimer(start_updates,1);
});

var start_updates = func {
    if (getprop("position/gear-agl-ft")>30)
    {
        # airborne startup
        Startup();
        setprop("/controls/gear/brake-parking",0);
        controls.gearDown(-1);
    }
    update_systems();
}
                           
setlistener("/sim/signals/reinit", func {
    SndOut.setDoubleValue(0.15);
    Shutdown();
});

#setlistener("/autopilot/route-manager/route/num", func(wp){
#    var wpt= wp.getValue() -1;
#
#    if(wpt>-1){
#    setprop("instrumentation/groundradar/id",getprop("autopilot/route-manager/route/wp["~wpt~"]/id"));
#    }else{
#    setprop("instrumentation/groundradar/id",getprop("sim/tower/airport-id"));
#    }
#},1,0);

setlistener("/sim/current-view/internal", func(vw){
    if(vw.getValue()){
    SndOut.setDoubleValue(0.3);
    }else{
    SndOut.setDoubleValue(1.0);
    }
},1,0);

setlistener("/sim/model/start-idling", func(idle){
    var run= idle.getBoolValue();
    if(run){
    Startup();
    }else{
    Shutdown();
    }
},0,0);

setlistener("/instrumentation/clock/et-knob", func(et){
    var tmp = et.getValue();
    if(tmp == -1){
	    chronometer.reset();
   	}elsif(tmp==0){
	    chronometer.stop();
    }elsif(tmp==1){
    	chronometer.start();
    }
},0,0);

setlistener("instrumentation/transponder/mode-switch", func(transponder_switch){
    var mode = transponder_switch.getValue();
    var tcas_mode = 1;
    if (mode == 3) tcas_mode = 2;
    if (mode == 4) tcas_mode = 3;
    setprop("instrumentation/tcas/inputs/mode",tcas_mode);
},0,0);

setlistener("instrumentation/tcas/outputs/traffic-alert", func(traffic_alert){
    var alert = traffic_alert.getValue();
    # any TCAS alert enables the traffic display
    if (alert) setprop("instrumentation/radar/switch","on");
},0,0);

setlistener("controls/flight/speedbrake", func(spd_brake){
    var brake = spd_brake.getValue();
    # do not update lever when in AUTO position
    if ((brake==0)and(getprop("controls/flight/speedbrake-lever")==2))
    {
        setprop("controls/flight/speedbrake-lever",0);
    }
    elsif ((brake==1)and(getprop("controls/flight/speedbrake-lever")==0))
    {
        setprop("controls/flight/speedbrake-lever",2);
    }
},0,0);

setlistener("controls/flight/speedbrake-lever", func(spd_lever){
    var lever = spd_lever.getValue();
    controls.click(7);
    # do not set speedbrake property unless changed (avoid revursive updates)
    if ((lever==0)and(getprop("controls/flight/speedbrake")!=0))
    {
        setprop("controls/flight/speedbrake",0);
    }
    elsif ((lever==2)and(getprop("controls/flight/speedbrake")!=1))
    {
        setprop("controls/flight/speedbrake",1);
    }
},0,0);

controls.toggleAutoSpoilers = func() {
    # 0=spoilers retracted, 1=auto, 2=extended
    if (getprop("controls/flight/speedbrake-lever")!=1)
        setprop("controls/flight/speedbrake-lever",1);
    else
        setprop("controls/flight/speedbrake-lever",2*getprop("controls/flight/speedbrake"));
}

setlistener("controls/flight/flaps", func { controls.click(6) } );
setlistener("/controls/gear/gear-down", func { controls.click(8) } );
controls.gearDown = func(v) {
    if (v < 0) {
        if(!getprop("gear/gear[1]/wow"))setprop("/controls/gear/gear-down", 0);
    } elsif (v > 0) {
      setprop("/controls/gear/gear-down", 1);
    }
}

controls.toggleLandingLights = func()
{
    var state = getprop("controls/lighting/landing-light[1]");
    setprop("controls/lighting/landing-light[0]",!state);
    setprop("controls/lighting/landing-light[1]",!state);
    setprop("controls/lighting/landing-light[2]",!state);
}

var Startup = func{
screen.log.write("O nie, nie ma tak latwo! Uruchom go recznie.", 1, 0, 0);
screen.log.write("(No way, it's not that easy! Start it up manually.)", 1, 0, 0);
}

var Shutdown = func{
setprop("/sim/sound/music_b",0);
setprop("/controls/gear/brake-parking",1);
setprop("/controls/electric/APU-button",-1);
setprop("/aaa/lwiper/degrees",0.00);
setprop("/aaa/rwiper/degrees",0.00);
setprop("controls/electric/engine[0]/generator",0);
setprop("controls/electric/engine[1]/generator",0);
setprop("controls/electric/engine[0]/bus-tie",0);
setprop("controls/electric/engine[1]/bus-tie",0);
setprop("controls/electric/APU-generator",0);
setprop("controls/electric/avionics-switch",0);
setprop("controls/electric/battery-switch",0);
setprop("controls/electric/inverter-switch",0);
setprop("controls/lighting/instruments-norm",0);
setprop("controls/lighting/nav-lights",0);
setprop("controls/lighting/beacon",0);
setprop("controls/lighting/strobe",0);
setprop("controls/lighting/wing-lights",0);
setprop("controls/lighting/taxi-lights",0);
setprop("controls/lighting/logo-lights",0);
setprop("controls/lighting/cabin-lights",0);
setprop("controls/lighting/landing-light[0]",0);
setprop("controls/lighting/landing-light[1]",0);
setprop("controls/lighting/landing-light[2]",0);
setprop("controls/lighting/strobe",0);
setprop("controls/lighting/beacon",0);
setprop("controls/engines/engine[0]/cutoff",1);
setprop("controls/engines/engine[1]/cutoff",1);
setprop("controls/fuel/tank/boost-pump",0);
setprop("controls/fuel/tank/boost-pump[1]",0);
setprop("controls/fuel/tank[1]/boost-pump",0);
setprop("controls/fuel/tank[1]/boost-pump[1]",0);
setprop("controls/fuel/tank[2]/boost-pump",0);
setprop("controls/fuel/tank[2]/boost-pump[1]",0);
setprop("/consumables/fuel/tank[0]/selected",0);
setprop("/consumables/fuel/tank[1]/selected",0);
setprop("/consumables/fuel/tank[2]/selected",0);
setprop("sim/model/armrest",0);
setprop("/aaa/xfeed_progr", 0);
setprop("/aaa/xfeed_1", 0);
setprop("/aaa/xfeed_2", 0);
setprop("/controls/lighting/cabin-lights", 1);
props.globals.getNode("/aaa/bleed_air/L_PACK", 0).setBoolValue(0);
props.globals.getNode("/aaa/bleed_air/R_PACK", 0).setBoolValue(0);
props.globals.getNode("/aaa/bleed_air/L_TRIM", 0).setBoolValue(0);
props.globals.getNode("/aaa/bleed_air/R_TRIM", 0).setBoolValue(0);
props.globals.getNode("/aaa/bleed_air/L_ISLN", 0).setBoolValue(0);
props.globals.getNode("/aaa/bleed_air/C_ISLN", 0).setBoolValue(0);
props.globals.getNode("/aaa/bleed_air/R_ISLN", 0).setBoolValue(0);
props.globals.getNode("/aaa/bleed_air/L_ENG", 0).setBoolValue(0);
props.globals.getNode("/aaa/bleed_air/APU", 0).setBoolValue(0);
props.globals.getNode("/aaa/bleed_air/R_ENG", 0).setBoolValue(0);
setprop("/instrumentation/efis/mfd/mode-num", 3);
setprop("/instrumentation/efis/mfd/display-mode", "INFORMATION");
setprop("/instrumentation/efis/mfd2/mode-num", 3);
setprop("/instrumentation/efis/mfd2/display-mode", "INFORMATION");
setprop("/instrumentation/radar/switch", "off");
setprop("/aaa/deice/di1", 0);
setprop("/aaa/deice/di2", 0);
setprop("/aaa/deice/di3", 0);
setprop("/aaa/deice/di4", 0);
setprop("/aaa/outflow/ofv1", 0);
setprop("/aaa/outflow/ofv2", 0);
setprop("/aaa/efb/mode", "off");
setprop("/aaa/mfd_buttons/left", 0);
setprop("/aaa/mfd_buttons/center", 0);
setprop("/aaa/mfd_buttons/right", 1);
setprop("/aaa/anti-ice/left", -1);
setprop("/aaa/anti-ice/center", -1);
setprop("/aaa/anti-ice/right", -1);
setprop("/aaa/flightdeck-norm", 0.22);
setprop("/instrumentation/efis/mfd3/display-mode", "EICAS2");
setprop("/aaa/no-smkg", 0);
setprop("/aaa/seatbelts", 0);
setprop("/aaa/lheater", -1);
setprop("/aaa/rheater", -1);
setprop("/instrumentation/efis/inputs/range", 10);
setprop("/aaa/hydraulic/air_l", -1);
setprop("/aaa/hydraulic/air_c1", -1);
setprop("/aaa/hydraulic/air_c2", -1);
setprop("/aaa/hydraulic/air_r", -1);
setprop("/aaa/jettison", 0);
setprop("/aaa/rat", 0);
props.globals.getNode("/aaa/flightdeck-norm").setDoubleValue(0.2);
props.globals.getNode("/aaa/displays-norm").setDoubleValue(1);
props.globals.getNode("/aaa/flightdeck-green-norm").setDoubleValue(0.8);
props.globals.getNode("/aaa/route/show", 1).setBoolValue(0);
props.globals.getNode("/controls/hydraulic/system[0]/electric-pump").setBoolValue(0);
props.globals.getNode("/controls/hydraulic/system[1]/electric-pump").setBoolValue(0);
props.globals.getNode("/controls/hydraulic/system[2]/electric-pump").setBoolValue(0);
props.globals.getNode("/controls/hydraulic/system[3]/electric-pump").setBoolValue(0);
setprop("/aaa/switches/switch301", 0);
setprop("/aaa/switches/switch302", 0);
setprop("/aaa/switches/switch401", -1);
setprop("/aaa/switches/switch402", 0);
setprop("/aaa/switches/switch101", 0);
setprop("/aaa/switches/switch102", 0);
setprop("/aaa/switches/switch201", 0);
setprop("/aaa/switches/switch202", 0);
setprop("/aaa/switches/switch63", 0);
setprop("/aaa/switches/switch62", 0);
setprop("/aaa/switches/EVAC001", 0);
setprop("/aaa/switches/EVACHORN1", 0);
setprop("/aaa/animation/evacuation", 0);
setprop("/aaa/switches/switch401", 0);
setprop("/aaa/switches/switch402", 0);
setprop("/aaa/switches/oxygenswitch", 0);
setprop("/aaa/oh/switches/switch10002", 0);
setprop("/aaa/oh/switches/switch10003", 0);
setprop("/aaa/oh/switches/switch11002", 0);
setprop("/aaa/oh/switches/switch11003", 0);
setprop("/aaa/oh/switches/switch12002", 0);
setprop("/aaa/oh/switches/switch12003", 0);
setprop("/aaa/oh/switches/switch13002", 0);
setprop("/aaa/oh/switches/switch13003", 0);
setprop("/aaa/oh/switches/switch14002", 0);
setprop("/aaa/oh/switches/switch14003", 0);
setprop("/aaa/oh/switches/switch15002", 0);
setprop("/aaa/oh/switches/switch15003", 0);
setprop("/aaa/oh/switches/switch16002", 0);
setprop("/aaa/oh/switches/switch16003", 0);
setprop("/aaa/oh/switches/switch17002", 0);
setprop("/aaa/oh/switches/switch17003", 0);
setprop("/aaa/oh/switches/switch18002", 0);
setprop("/aaa/oh/switches/switch18003", 0);
setprop("/aaa/oh/switches/switch19002", 0);
setprop("/aaa/oh/switches/switch19003", 0);
setprop("/aaa/oh/switches/switch20002", 0);
setprop("/aaa/oh/switches/switch20003", 0);
setprop("/aaa/oh/switches/switch21002", 0);
setprop("/aaa/oh/switches/switch21003", 0);
setprop("/aaa/oh/switches/switch22002", 0);
setprop("/aaa/oh/switches/switch22003", 0);
setprop("/aaa/oh/switches/rrwytoggle", 0);
setprop("/aaa/oh/switches/lrwytoggle", 0);
setprop("/aaa/oh/switches/indtoggle", 0);
setprop("/aaa/oh/switches/indtoggle001", 0);
setprop("/aaa/oh/switches/indtoggle002", 0);
setprop("/aaa/oh/switches/audio_ent001", 0);
setprop("/aaa/oh/switches/servintph", 0);
setprop("/aaa/oh/switches/buttoncase001", 0);
setprop("/aaa/oh/switches/buttoncase002", 0);
setprop("/aaa/oh/switches/buttoncase003", 0);
setprop("/aaa/oh/switches/buttoncase004", 0);
setprop("/aaa/oh/switches/buttoncase005", 0);
setprop("/aaa/oh/switches/buttoncase006", 0);
setprop("/aaa/oh/switches/buttoncase007", 0);
setprop("/aaa/oh/switches/buttoncase008", 0);
setprop("/aaa/oh/switches/buttoncase009", 0);
setprop("/aaa/oh/switches/bezpiecznik", 0);
setprop("/aaa/oh/switches/bezpiecznik1", 0);
setprop("/aaa/oh/switches/bezpiecznik2", 0);
setprop("/aaa/oh/switches/bezpiecznik3", 0);
setprop("/aaa/oh/switches/bezpiecznik4", 0);
setprop("/aaa/oh/switches/bezpiecznik5", 0);
setprop("/aaa/oh/switches/bezpiecznik6", 0);
setprop("/aaa/oh/switches/bezpiecznik7", 0);
setprop("/aaa/oh/switches/bezpiecznik8", 0);
setprop("/aaa/oh/switches/bezpiecznik9", 0);
setprop("/aaa/oh/switches/bezpiecznik10", 0);
setprop("/aaa/oh/switches/bezpiecznik11", 0);
setprop("/aaa/oh/switches/bezpiecznik12", 0);
setprop("/aaa/oh/switches/bezpiecznik13", 0);
setprop("/aaa/oh/switches/bezpiecznik14", 0);
setprop("/aaa/oh/switches/bezpiecznik15", 0);
setprop("/aaa/oh/switches/bezpiecznik16", 0);
setprop("/aaa/oh/switches/bezpiecznik17", 0);
setprop("/aaa/oh/switches/bezpiecznik18", 0);
setprop("/aaa/oh/switches/bezpiecznik19", 0);
setprop("/aaa/oh/switches/bezpiecznik20", 0);
setprop("/aaa/oh/switches/bezpiecznik21", 0);
setprop("/aaa/oh/switches/bezpiecznik22", 0);
setprop("/aaa/oh/switches/bezpiecznik23", 0);
setprop("/aaa/oh/switches/bezpiecznik24", 0);
setprop("/aaa/oh/switches/bezpiecznik25", 0);
setprop("/aaa/oh/switches/bezpiecznik26", 0);
setprop("/aaa/oh/switches/bezpiecznik27", 0);
setprop("/aaa/oh/switches/bezpiecznik28", 0);
setprop("/aaa/oh/switches/bezpiecznik29", 0);
setprop("/aaa/oh/switches/bezpiecznik30", 0);
setprop("/aaa/oh/switches/bezpiecznik31", 0);
setprop("/aaa/oh/switches/bezpiecznik32", 0);
setprop("/aaa/oh/switches/bezpiecznik33", 0);
setprop("/aaa/oh/switches/bezpiecznik34", 0);
setprop("/aaa/oh/switches/bezpiecznik35", 0);
setprop("/aaa/oh/switches/bezpiecznik36", 0);
setprop("/aaa/oh/switches/bezpiecznik37", 0);
setprop("/aaa/oh/switches/bezpiecznik38", 0);
setprop("/aaa/oh/switches/bezpiecznik39", 0);
setprop("/aaa/oh/switches/bezpiecznik40", 0);
setprop("/aaa/oh/switches/bezpiecznik41", 0);
setprop("/aaa/oh/switches/bezpiecznik44", 0);
setprop("/aaa/oh/switches/bezpiecznik43", 0);
setprop("/aaa/oh/switches/bezpiecznik44", 0);
setprop("/aaa/oh/switches/bezpiecznik45", 0);
setprop("/aaa/oh/switches/bezpiecznik46", 0);
setprop("/aaa/oh/switches/bezpiecznik47", 0);
setprop("/aaa/oh/switches/bezpiecznik48", 0);
setprop("/aaa/oh/switches/bezpiecznik49", 0);
setprop("/aaa/oh/switches/bezpiecznik50", 0);
setprop("/aaa/oh/switches/bezpiecznik51", 0);
setprop("/aaa/oh/switches/bezpiecznik52", 0);
setprop("/aaa/oh/switches/bezpiecznik53", 0);
setprop("/aaa/oh/switches/bezpiecznik54", 0);
setprop("/aaa/oh/switches/bezpiecznik55", 0);
setprop("/aaa/oh/switches/bezpiecznik56", 0);
setprop("/aaa/oh/switches/bezpiecznik57", 0);
setprop("/aaa/oh/switches/bezpiecznik58", 0);
setprop("/aaa/oh/switches/bezpiecznik59", 0);
setprop("/aaa/oh/switches/bezpiecznik60", 0);
setprop("/aaa/oh/switches/bezpiecznik61", 0);
setprop("/aaa/oh/switches/bezpiecznik62", 0);
setprop("/aaa/oh/switches/bezpiecznik63", 0);
setprop("/aaa/oh/switches/bezpiecznik64", 0);
setprop("/aaa/oh/switches/bezpiecznik65", 0);
setprop("/aaa/oh/switches/bezpiecznik66", 0);
setprop("/aaa/oh/switches/bezpiecznik67", 0);
setprop("/aaa/oh/switches/bezpiecznik68", 0);
setprop("/aaa/oh/switches/bezpiecznik69", 0);
setprop("/aaa/oh/switches/bezpiecznik70", 0);
setprop("/aaa/oh/switches/bezpiecznik71", 0);
setprop("/aaa/oh/switches/bezpiecznik74", 0);
setprop("/aaa/oh/switches/bezpiecznik73", 0);
setprop("/aaa/oh/switches/bezpiecznik74", 0);
setprop("/aaa/oh/switches/bezpiecznik75", 0);
setprop("/aaa/oh/switches/bezpiecznik76", 0);
setprop("/aaa/oh/switches/bezpiecznik77", 0);
setprop("/aaa/oh/switches/bezpiecznik78", 0);
setprop("/aaa/oh/switches/bezpiecznik79", 0);
setprop("/aaa/oh/switches/bezpiecznik80", 0);
setprop("/aaa/oh/switches/bezpiecznik81", 0);
setprop("/aaa/oh/switches/bezpiecznik82", 0);
setprop("/aaa/oh/switches/bezpiecznik83", 0);
setprop("/aaa/oh/switches/bezpiecznik84", 0);
setprop("/aaa/oh/switches/bezpiecznik85", 0);
setprop("/aaa/oh/switches/bezpiecznik86", 0);
setprop("/aaa/oh/switches/bezpiecznik87", 0);
setprop("/aaa/oh/switches/bezpiecznik88", 0);
setprop("/aaa/oh/switches/bezpiecznik89", 0);
setprop("/aaa/oh/switches/bezpiecznik90", 0);
setprop("/aaa/oh/switches/bezpiecznik91", 0);
setprop("/aaa/oh/switches/bezpiecznik92", 0);
setprop("/aaa/oh/switches/bezpiecznik93", 0);
setprop("/aaa/oh/switches/bezpiecznik94", 0);
setprop("/aaa/oh/switches/bezpiecznik95", 0);
setprop("/aaa/oh/switches/bezpiecznik96", 0);
setprop("/aaa/oh/switches/bezpiecznik97", 0);
setprop("/aaa/oh/switches/bezpiecznik98", 0);
setprop("/aaa/oh/switches/bezpiecznik99", 0);
setprop("/aaa/oh/switches/bezpiecznik100", 0);
setprop("/aaa/oh/switches/bezpiecznik101", 0);
setprop("/aaa/oh/switches/bezpiecznik102", 0);
setprop("/aaa/oh/switches/bezpiecznik103", 0);
setprop("/aaa/oh/switches/bezpiecznik104", 0);
setprop("/aaa/oh/switches/bezpiecznik105", 0);
setprop("/aaa/oh/switches/bezpiecznik106", 0);
setprop("/aaa/oh/switches/bezpiecznik107", 0);
setprop("/aaa/oh/switches/bezpiecznik108", 0);
setprop("/aaa/oh/switches/bezpiecznik109", 0);
setprop("/aaa/oh/switches/bezpiecznik110", 0);
setprop("/aaa/oh/switches/bezpiecznik111", 0);
setprop("/aaa/oh/switches/bezpiecznik112", 0);
setprop("/aaa/oh/switches/bezpiecznik113", 0);
setprop("/aaa/oh/switches/bezpiecznik114", 0);
setprop("/aaa/oh/switches/bezpiecznik115", 0);
setprop("/aaa/oh/switches/bezpiecznik116", 0);
setprop("/aaa/oh/switches/bezpiecznik117", 0);
setprop("/aaa/oh/switches/bezpieczniktcas", 0);
setprop("/aaa/oh/knobs/MSTRpanel", 0);
setprop("/aaa/oh/knobs/MSTRpanel001", 0);
setprop("/aaa/oh/knobs/MSTRpanel002", 0);
setprop("/aaa/oh/knobs/MSTRpanel00101", 0);
setprop("/aaa/oh/knobs/MSTRpanel00201", 0);
setprop("/aaa/oh/knobs/rengice001", 0);
setprop("/aaa/oh/knobs/rengice002", 0);
setprop("/aaa/oh/knobs/cargoaft", 0);
setprop("/aaa/oh/knobs/cargofwd", 0);
setprop("/aaa/pdstl/switches/buttoncase010", 0);
props.globals.getNode("/aaa/oh/adiru", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf1", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf2", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf3", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf4", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf5", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf6", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf7", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf8", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf9", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf10", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf11", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf12", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf13", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf14", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/cf15", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/ac1", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/ac2", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/ac3", 1).setBoolValue(0);
props.globals.getNode("/aaa/oh/ac4", 1).setBoolValue(0);
props.globals.getNode("/aaa/fd/cf01", 1).setBoolValue(0);
props.globals.getNode("/aaa/fd/cf02", 1).setBoolValue(0);
props.globals.getNode("/aaa/fd/cf03", 1).setBoolValue(0);
setprop("/aaa/pdstl/knobs/radio1001", 0);
setprop("/aaa/pdstl/knobs/radio2001", 0);
setprop("/aaa/pdstl/knobs/radio3001", 0);
setprop("/aaa/pdstl/knobs/radio4001", -0.85);
setprop("/aaa/pdstl/knobs/radio5001", -0.85);
setprop("/aaa/pdstl/knobs/radio6001", -0.85);
setprop("/aaa/pdstl/knobs/radio7001", -0.85);
setprop("/aaa/pdstl/knobs/radio8001", 0.20);
setprop("/aaa/pdstl/knobs/radio9001", 0.20);
setprop("/aaa/pdstl/knobs/radio10001", -0.85);
setprop("/aaa/pdstl/knobs/radio11001", -0.85);
setprop("/aaa/pdstl/knobs/radio12001", -0.85);
setprop("/aaa/pdstl/knobs/radio13001", 0);
setprop("/aaa/pdstl/knobs/radio14001", 0);
setprop("/aaa/pdstl/knobs/radio15001", -0.85);
setprop("/aaa/pdstl/knobs/radio16001", -0.85);
setprop("/aaa/pdstl/buttons/audio1001", 0);
setprop("/aaa/pdstl/buttons/audio2001", 0);
setprop("/aaa/pdstl/buttons/audio3001", 0);
setprop("/aaa/pdstl/buttons/audio4001", 0);
setprop("/aaa/pdstl/buttons/audio5001", 0);
setprop("/aaa/pdstl/buttons/audio6001", 1);
setprop("/aaa/pdstl/buttons/audio7001", 0);
setprop("/aaa/pdstl/buttons/audio8001", 0);
setprop("/aaa/pdstl/buttons/audio9001", 0);
setprop("/aaa/pdstl/buttons/audio10001", 0);
setprop("/aaa/pdstl/switches/audioswitch", 0);
setprop("/aaa/pdstl/switches/floorlightswitch", 0);
setprop("/aaa/hydraulic/air_l_knob", -1);
setprop("/aaa/hydraulic/air_c1_knob", -1);
setprop("/aaa/hydraulic/air_c2_knob", -1);
setprop("/aaa/hydraulic/air_r_knob", -1);
props.globals.getNode("/aaa/route/x1", 0).setDoubleValue(0);
props.globals.getNode("/aaa/route/y1", 0).setDoubleValue(-80);
props.globals.getNode("/aaa/route/x2", 0).setDoubleValue(0);
props.globals.getNode("/aaa/route/y2", 0).setDoubleValue(-80);
if (getprop("/sim/model/start-idling")) setprop("/sim/model/start-idling",0);
setprop("instrumentation/transponder/mode-switch",0); # transponder mode: off
}

var click_reset = func(propName) {
    setprop(propName,0);
}
controls.click = func(button) {
    if (getprop("sim/freeze/replay-state"))
        return;
    var propName="sim/sound/click"~button;
    setprop(propName,1);
    settimer(func { click_reset(propName) },0.4);
}

var update_systems = func {
    Efis.calc_kpa();
    Efis.update_temp();
    LHeng.update();
    RHeng.update();
    wiper1.active();
	wiper2.active();
    if(getprop("controls/gear/gear-down")){
        setprop("sim/multiplay/generic/float[0]",getprop("gear/gear[0]/compression-m"));
        setprop("sim/multiplay/generic/float[1]",getprop("gear/gear[1]/compression-m"));
        setprop("sim/multiplay/generic/float[2]",getprop("gear/gear[2]/compression-m"));
    }
    var et_tmp = getprop("/instrumentation/clock/ET-sec");
   
    var et_min = int(et_tmp * 0.0166666666667);
    var et_hr = int(et_min * 0.0166666666667) * 100;
    et_tmp = et_hr+et_min;
    setprop("instrumentation/clock/ET-display",et_tmp);
	
    settimer(update_systems,0);
}