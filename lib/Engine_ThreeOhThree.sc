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

		this.addCommand("tot_play","ffffffffff",{ arg msg;
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
		// </tot>
	}

	free {
		// <tot>
		totSynth.free;
		// </tot>
	}
}
