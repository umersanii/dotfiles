function subs --description "Live subtitles from system audio via whisper"
    set monitor easyeffects_sink.monitor
    set model /usr/share/whisper.cpp-model-small.en-q5_1/ggml-small.en-q5_1.bin

    if not test -f $model
        echo "Model not found: $model"
        echo "Install with: yay -S whisper.cpp-model-small.en-q5_1"
        return 1
    end

    echo "▶ Subtitles active (Ctrl+C to stop)"
    echo ""

    while true
        # Record 5s of system audio output
        ffmpeg -f pulse -i $monitor -t 5 -ac 1 -ar 16000 -y /tmp/subs_chunk.wav -loglevel quiet

        # Transcribe to text file (no timestamps)
        whisper-cli -m $model -f /tmp/subs_chunk.wav -otxt -of /tmp/subs_out -np 2>/dev/null

        # Display result
        if test -f /tmp/subs_out.txt
            set text (string trim (cat /tmp/subs_out.txt))
            if test -n "$text"
                clear
                echo $text
            end
            rm -f /tmp/subs_out.txt
        end
    end
end
