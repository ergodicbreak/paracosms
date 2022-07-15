// Engine_Paracosms

// Inherit methods from CroneEngine
Engine_Paracosms : CroneEngine {

    // Paracosms specific v0.1.0
    var paracosms;
    var ouroboros;
    var fnOSC;
    var startup;
    var startupNum;
    // Paracosms ^

    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

    alloc {
        // Paracosms specific v0.0.1
        startup=0;
        startupNum=0.0;
        fnOSC= OSCFunc({
            arg msg, time;
            if (msg[2]>0,{
                // cursor ID, POSITION
                NetAddr("127.0.0.1", 10111).sendMsg("data",msg[2],msg[3]);
            });
        },'/tr', context.server.addr);
        context.server.sync;
        paracosms=Paracosms.new(context.server,0,"/home/we/dust/data/paracosms/cache");
        ouroboros=Ouroboros.new(context.server,0);
        context.server.sync;

        this.addCommand("add","is", { arg msg;
            if (startup>0,{
                startupNum=startupNum+1.0;
                Routine {
                    (startupNum/10.0).wait;
                    paracosms.add(msg[1],msg[2].asString);
                }.play;
            },{
                paracosms.add(msg[1],msg[2].asString);
            });
        });
        this.addCommand("watch","i", { arg msg;
            paracosms.watch(msg[1]);
        });
        this.addCommand("play","i", { arg msg;
            paracosms.play(msg[1]);
        });
        this.addCommand("stop","i", { arg msg;
            paracosms.stop(msg[1]);
        });
        this.addCommand("set","isff", { arg msg;
            paracosms.set(msg[1],msg[2],msg[3],msg[4]);
        });
        this.addCommand("resetPhase","", { arg msg;
            paracosms.resetPhase();
        });
        this.addCommand("record","isfff", { arg msg;
            var id=msg[1];
            var filename=msg[2];
            var seconds=msg[3];
            var crossfade=msg[4];
            var threshold=msg[5];
            ouroboros.record(seconds,crossfade,threshold,{
              NetAddr("127.0.0.1", 10111).sendMsg("recording",id,filename);
            },{ arg buf;
                ["done",buf,"writing",filename].postln;
                buf.write(filename.asString,headerFormat: "wav", sampleFormat: "int16", completionMessage:{
                    ["wrote",buf].postln;
                    NetAddr("127.0.0.1", 10111).sendMsg("recorded",id,filename);
                });
            });
        });	
        this.addCommand("startup","i",{arg msg;
            startup=msg[1];
            startupNum=0;
        })


        // ^ Paracosms specific

    }

    free {
        // Paracosms Specific v0.0.1
        paracosms.free;
        fnOSC.free;
        // ^ Paracosms specific
    }
}
