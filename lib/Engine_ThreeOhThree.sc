// Engine_ThreeOhThree
Engine_ThreeOhThree : CroneEngine {
	// <tot>
	var totSynth;
	// </tot>


	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		// <tot>

		SynthDef("synthy",{
			arg out=0,hz=220,amp=0.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.5,decay=0.2,sustain=0.9,release=1,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,note,env,detune,stereo,lowcut,chorus,res;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			note=Lag.kr(hz,portamento).cpsmidi+bend;
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			sub=Lag.kr(sub,1);
			snd=Pan2.ar(Pulse.ar((note-12).midicps,LinLin.kr(LFTri.kr(0.5),-1,1,0.2,0.8))*sub);
			stereo=LinLin.kr(mod1,-1,1,0,1);
			lowcut=LinExp.kr(mod2,-1,1,25,11000);
			res=LinExp.kr(mod3,-1,1,0.25,1.75);
			detune=LinExp.kr(mod4,-1,1,0.00001,0.3);
			snd=snd+Mix.ar({
				arg i;
				var snd2;
				snd2=SawDPW.ar((note+(detune*(i*2-1))).midicps);
				snd2=RLPF.ar(snd2,LinExp.kr(SinOsc.kr(rrand(1/30,1/10),rrand(0,2*pi)),-1,1,lowcut,12000),res);
				snd2=DelayC.ar(snd2, rrand(0.01,0.03), LFNoise1.kr(Rand(5,10),0.01,0.02)/15);
				Pan2.ar(snd2,VarLag.kr(LFNoise0.kr(1/3),3,warp:\sine)*stereo)
			}!4);
			Out.ar(out,snd*env*amp/8);
		}).add;

		// https://sccode.org/1-4Wy
		// https://modwiggler.com/forum/viewtopic.php?t=167732
		// https://www.firstpr.com.au/rwi/dfish/303-unique.html
		// https://www.firstpr.com.au/rwi/dfish/303-slide.html
		// https://github.com/monome/dust/blob/master/lib/sc/Engine_PolyPerc.sc
		SynthDef("sc303",{
			arg  out=0, 
			t_trig=0, amp=0.0, note=60, 
			wave=0, ctf=100, res=0.2,
			sus=0, dec=1.0, env=1000, 
			port=0;
			var  filEnv, volEnv, waves, snd, fil, freq;

			freq = Lag.kr(note.midicps,port);

			volEnv =  EnvGen .ar( Env .new([10e-10, 1, 1, 10e-10], [0.01, sus, dec],  'exp' ), t_trig).poll;
			filEnv =  EnvGen .ar( Env .new([10e-10, 1, 10e-10], [0.01, dec],  'exp' ), t_trig);

			snd = SelectX.ar(wave,[ Saw .ar([freq,freq+0.01], volEnv),  Pulse .ar([freq,freq+0.01], 0.5, volEnv)]);

			fil = ctf + (filEnv*env);
			snd = RLPF.ar(snd, fil, res);
			snd = snd * amp;
			Out .ar(out, snd);
		}).add;

		context.server.sync;

		totSynth=Synth.new("sc303");

		this.addCommand("tot_bass","ffffffffff",{ arg msg;
			totSynth.set(
				\t_trig,1,
				\amp,msg[2],
				\note,msg[3],
				\wave,msg[4],
				\ctf,msg[5],
				\res,msg[6],
				\sus,msg[7],
				\dec,msg[8],
				\env,msg[9],
				\port,msg[10],
			);
		});
		
		this.addCommand("tot_pad","fff",{ arg msg;
			Synth.new("synthy",[
				\amp,msg[1],
				\hz,msg[2].midicps,
				\duration,msg[3],
			]);
		});
		// </tot>
	}

	free {
		// <tot>
		totSynth.free;
		// </tot>
	}
}
