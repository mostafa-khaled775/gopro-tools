#!/bin/bash

# **************************************************
# Title: Davinci Resolve On Linux Media Prepper
# **************************************************

# Introduction:
# I have been working on a script to transcode all of my GoPro MP4 files, TS files 
# (from Rearview Camera in vehicle), and of course, GoPro 360 files into .mov files 
# so I can use them in Linux with Davinci Resolve. This script, when run in the top 
# directory, will search all subdirectories for any files that match the criteria 
# and then transcode them into a .mov file. For MP4 files, it isn't actually transcoding 
# the content; it is simply changing the container from .MP4 to .mov so that Davinci Resolve 
# will open them. For the 360 files, it gives an option to transcode and remap, which 
# will make the resulting .mov file usable and flat, with everything mapped to the right location. 
# All of the files are put into a new directory with "- Processed" added to the end, and the 
# original files are left untouched.
#
# If you're interested, you can take a look here for the script:
#
# https://github.com/atlasamerican/gopro-tools/blob/bash-script/transcode-videos
#
# Now... a couple of caveats... I do not take credit for the ffmpeg filter_complex. 
# I only made a small tweak to allow for encoding via h264, resulting in much more 
# reasonable file sizes. The person responsible for the hard work, you can find their code here:
#
# https://github.com/dawonn/gopro-max-video-tools
#
# The second and most significant caveat... I am not a coder. I used ChatGPT to help me create 
# this script. Quite a bit of trial and error. If anyone that is a real coder wants to take it 
# from here and make improvements, have at it. I am already at my limits, and I am sure there 
# are a lot of ways this could be made better.
#
# **************************************************

# Initialization
media_files_processed=0
files_360_processed=0
status_interval=2

# Trap CTRL+C (SIGINT) to clean up and exit gracefully
trap 'cleanup_and_exit' SIGINT

cleanup_and_exit() {
    echo "CTRL+C detected! Stopping processes and cleaning up..."
    pkill -f ffmpeg
    echo "Cleaned up. Exiting."
    exit 1
}

display_title() {
    echo "**************************************************"
    echo "Title: Davinci Resolve On Linux Media Prepper"
    echo "**************************************************"
}

prompt_user() {
    display_title
    echo "Enter input folder path (default is current folder):"
    read -r input_folder
    input_folder=${input_folder:-$PWD}

    echo "Selected input folder: $input_folder"

    echo "Enter output folder path (default is [InputFolder] - Processed):"
    read -r dest_folder
    dest_folder=${dest_folder:-"${input_folder} - Processed"}

    echo "Selected output folder: $dest_folder"

    mkdir -p "$dest_folder"

    echo "Choose action for 360 files:"
    echo "  1. Change container to .mov"
    echo "  2. Remap & change container"
    echo "  3. Remap only"
    read -r action

    if [ "$action" -eq 2 ] || [ "$action" -eq 3 ]; then
        echo ""
        echo "Select quality level for remapping/transcoding 360 files:"
        echo "  1. Ultra Fast (low quality, large file size)"
        echo "  2. Very Fast (medium-low quality, medium-large file size)"
        echo "  3. Medium (medium quality, medium file size)"
        echo "  4. Slow (high quality, small file size)"
        read -r quality_choice

        case $quality_choice in
            1) preset="ultrafast" ;;
            2) preset="veryfast" ;;
            3) preset="medium" ;;
            4) preset="slow" ;;
            *) echo "Invalid choice. Defaulting to 'medium' preset." ; preset="medium" ;;
        esac
    fi

    echo "Overwrite existing files?"
    echo "  1. Yes, overwrite all existing files"
    echo "  2. No, skip existing files"
    echo "  3. Only overwrite if the existing file is 0 bytes"
    read -r overwrite_choice
    case $overwrite_choice in
        1) overwrite_files="always" ;;
        2) overwrite_files="never" ;;
        3) overwrite_files="if_zero" ;;
        *) echo "Invalid choice. Defaulting to 'never'"; overwrite_files="never" ;;
    esac

    echo "Copy non-media files? (y/n)"
    read -r copy_choice
    copy_non_media_files=$( [ "$copy_choice" == "y" ] && echo true || echo false )

    # Determine the number of threads available
    total_threads=$(nproc)
    default_threads=$((total_threads / 2))

    echo "Your system has $total_threads threads available."
    echo "The default setting is $default_threads threads."
    echo "Note: Increasing the number of threads may not result in faster processing due to the linearity of video processing for remap and transcode."
    echo "Would you like to change the number of threads? (Default: $default_threads, Enter a number or press Enter to use default):"
    read -r thread_choice
    threads=${thread_choice:-$default_threads}

    # Gather file statistics
    media_files_total=$(find "$input_folder" -type f \( -iname "*.mp4" -o -iname "*.ts" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.flv" -o -iname "*.wmv" \) | wc -l)
    files_360_total=$(find "$input_folder" -type f -iname "*.360" | wc -l)
}

update_status() {
    clear
    echo "***************************************************"
    echo "Title: Davinci Resolve On Linux Media Prepper"
    echo "***************************************************"
    echo "              Processing Status"
    echo "***************************************************"
    echo "Media Files Processed: $media_files_processed of $media_files_total"
    echo "360 Files Processed: $files_360_processed of $files_360_total"
    echo "***************************************************"
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"% used"}')"
    echo "Memory Usage: $(free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2}')"
    echo "***************************************************"
}

ffmpeg_process_360() {
    local input_file="$1"
    local output_file="$2"
    local preset="$3"
    local div=65  # As defined in your provided mapping

    # Using your provided filter for remapping and transcoding
    ffmpeg -y -nostdin -threads "$threads" -i "$input_file" -filter_complex "
    [0:v]crop=128:1344:x=624:y=0,format=yuvj420p,
    geq=
    lum='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    cb='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    cr='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    a='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    interpolation=b,crop=64:1344:x=0:y=0,format=yuvj420p,scale=96:1344[crop],
    [0:v]crop=624:1344:x=0:y=0,format=yuvj420p[left], 
    [0:v]crop=624:1344:x=752:y=0,format=yuvj420p[right], 
    [left][crop]hstack[leftAll], 
    [leftAll][right]hstack[leftDone],

    [0:v]crop=1344:1344:1376:0[middle],

    [0:v]crop=128:1344:x=3344:y=0,format=yuvj420p,
    geq=
    lum='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    cb='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    cr='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    a='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    interpolation=b,crop=64:1344:x=0:y=0,format=yuvj420p,scale=96:1344[cropRightBottom],
    [0:v]crop=624:1344:x=2720:y=0,format=yuvj420p[leftRightBottom], 
    [0:v]crop=624:1344:x=3472:y=0,format=yuvj420p[rightRightBottom], 
    [leftRightBottom][cropRightBottom]hstack[rightAll], 
    [rightAll][rightRightBottom]hstack[rightBottomDone],
    [leftDone][middle]hstack[leftMiddle],
    [leftMiddle][rightBottomDone]hstack[bottomComplete],

    [0:v]crop=128:1344:x=624:y=0,format=yuvj420p,
    geq=
    lum='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    cb='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    cr='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    a='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    interpolation=n,crop=64:1344:x=0:y=0,format=yuvj420p,scale=96:1344[leftTopCrop],
    [0:v]crop=624:1344:x=0:y=0,format=yuvj420p[firstLeftTop], 
    [0:v]crop=624:1344:x=752:y=0,format=yuvj420p[firstRightTop], 
    [firstLeftTop][leftTopCrop]hstack[topLeftHalf], 
    [topLeftHalf][firstRightTop]hstack[topLeftDone],

    [0:v]crop=1344:1344:1376:0[TopMiddle],

    [0:v]crop=128:1344:x=3344:y=0,format=yuvj420p,
    geq=
    lum='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    cb='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    cr='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    a='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/$div))+(p(X,Y)*(($div-((X+1)))/$div)), p(X,Y))':
    interpolation=n,crop=64:1344:x=0:y=0,format=yuvj420p,scale=96:1344[TopcropRightBottom],
    [0:v]crop=624:1344:x=2720:y=0,format=yuvj420p[TopleftRightBottom], 
    [0:v]crop=624:1344:x=3472:y=0,format=yuvj420p[ToprightRightBottom], 
    [TopleftRightBottom][TopcropRightBottom]hstack[ToprightAll], 
    [ToprightAll][ToprightRightBottom]hstack[ToprightBottomDone],
    [topLeftDone][TopMiddle]hstack[TopleftMiddle],
    [TopleftMiddle][ToprightBottomDone]hstack[topComplete],

    [bottomComplete]crop=in_w:in_h-1:0:0[bottomCropped],
    [topComplete]crop=in_w:in_h-1:0:0[topCropped],
    [bottomCropped][topCropped]vstack[complete], 
    [complete]v360=eac:e:interp=cubic[v]" \
    -map "[v]" -map "0:a:0" -c:v libx264 -preset "$preset" -crf 23 -pix_fmt yuv420p -c:a pcm_s16le -strict -2 -f mov "$output_file"

    touch -r "$input_file" "$output_file"
}

process_files() {
    local input_folder="$1"
    local dest_folder="$2"
    local file
    local input_file
    local output_file
    local output_subfolder

    # Process non-360 files first
    while IFS= read -r -d '' file; do
        input_file="$file"
        output_subfolder="$dest_folder/$(dirname "${input_file#$input_folder/}")"
        output_file="$output_subfolder/$(basename "${input_file%.*}.mov")"

        mkdir -p "$output_subfolder"

        if [[ -f "$output_file" ]]; then
            if [[ "$overwrite_files" == "never" ]]; then
                echo "$output_file already exists. Skipping..."
                continue
            elif [[ "$overwrite_files" == "if_zero" && ! -s "$output_file" ]]; then
                echo "$output_file is 0 bytes. Overwriting..."
            elif [[ "$overwrite_files" == "if_zero" && -s "$output_file" ]]; then
                echo "$output_file exists and is not 0 bytes. Skipping..."
                continue
            fi
        fi

        ffmpeg -y -nostdin -threads "$threads" -i "$input_file" -c:v copy -c:a pcm_s16le -strict experimental "$output_file"
        touch -r "$input_file" "$output_file"
        ((media_files_processed++))
        update_status
    done < <(find "$input_folder" -type f \( -iname "*.mp4" -o -iname "*.ts" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.flv" -o -iname "*.wmv" \) -print0)

    # Process 360 files after non-360 files
    while IFS= read -r -d '' file; do
        input_file="$file"
        output_subfolder="$dest_folder/$(dirname "${input_file#$input_folder/}")"
        output_file="$output_subfolder/$(basename "${input_file%.*}.mov")"

        mkdir -p "$output_subfolder"

        if [[ -f "$output_file" ]]; then
            if [[ "$overwrite_files" == "never" ]]; then
                echo "$output_file already exists. Skipping..."
                continue
            elif [[ "$overwrite_files" == "if_zero" && ! -s "$output_file" ]]; then
                echo "$output_file is 0 bytes. Overwriting..."
            elif [[ "$overwrite_files" == "if_zero" && -s "$output_file" ]]; then
                echo "$output_file exists and is not 0 bytes. Skipping..."
                continue
            fi
        fi

        ffmpeg_process_360 "$input_file" "$output_file" "$preset"
        ((files_360_processed++))
        update_status
    done < <(find "$input_folder" -type f -iname "*.360" -print0)

    # Optionally copy non-media files
    if [[ "$copy_non_media_files" == true ]]; then
        while IFS= read -r -d '' file; do
            output_subfolder="$dest_folder/$(dirname "${file#$input_folder/}")"
            mkdir -p "$output_subfolder"
            cp "$file" "$output_subfolder"
        done < <(find "$input_folder" -type f -not \( -iname "*.mp4" -o -iname "*.ts" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.flv" -o -iname "*.wmv" -o -iname "*.360" \) -print0)
    fi
}

# Main script execution
clear
prompt_user
update_status
process_files "$input_folder" "$dest_folder"
cleanup_and_exit
