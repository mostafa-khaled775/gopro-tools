#!/bin/bash

total_files_processed=0  # Initializing a counter for processed files

determine_destination() {
    current_dir_name="${PWD##*/}"
    dest="${PWD%/*}/${current_dir_name} - Processed"
    mkdir -p "$dest"
}

processed_name() {
    local input_file="$1"
    if [[ "$input_file" == *.360 ]]; then
        echo "$input_file"
    else
        echo "${input_file%.*}.mov"
    fi
}

ffmpeg_process() {
    local input_file="$1"
    local destination="$2"
    local preset="$3"  # Add the preset parameter
    local output_file="${destination}/${input_file%.*}.mov"
    
    # Check if the output file already exists
    if [[ -f "$output_file" ]]; then
        echo "$output_file already exists. Skipping..."
        return
    fi
    
    div=65
    
    # Your ffmpeg command here with the preset substitution
    ffmpeg -loglevel verbose -i "$input_file" -y -filter_complex "
    
    [0:0]crop=128:1344:x=624:y=0,format=yuvj420p,
    geq=
    lum='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    cb='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    cr='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    a='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    interpolation=b,crop=64:1344:x=0:y=0,format=yuvj420p,scale=96:1344[crop],
    [0:0]crop=624:1344:x=0:y=0,format=yuvj420p[left], 
    [0:0]crop=624:1344:x=752:y=0,format=yuvj420p[right], 
    [left][crop]hstack[leftAll], 
    [leftAll][right]hstack[leftDone],

    [0:0]crop=1344:1344:1376:0[middle],

    [0:0]crop=128:1344:x=3344:y=0,format=yuvj420p,
    geq=
    lum='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    cb='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    cr='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    a='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    interpolation=b,crop=64:1344:x=0:y=0,format=yuvj420p,scale=96:1344[cropRightBottom],
    [0:0]crop=624:1344:x=2720:y=0,format=yuvj420p[leftRightBottom], 
    [0:0]crop=624:1344:x=3472:y=0,format=yuvj420p[rightRightBottom], 
    [leftRightBottom][cropRightBottom]hstack[rightAll], 
    [rightAll][rightRightBottom]hstack[rightBottomDone],
    [leftDone][middle]hstack[leftMiddle],
    [leftMiddle][rightBottomDone]hstack[bottomComplete],

    [0:4]crop=128:1344:x=624:y=0,format=yuvj420p,
    geq=
    lum='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    cb='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    cr='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    a='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    interpolation=n,crop=64:1344:x=0:y=0,format=yuvj420p,scale=96:1344[leftTopCrop],
    [0:4]crop=624:1344:x=0:y=0,format=yuvj420p[firstLeftTop], 
    [0:4]crop=624:1344:x=752:y=0,format=yuvj420p[firstRightTop], 
    [firstLeftTop][leftTopCrop]hstack[topLeftHalf], 
    [topLeftHalf][firstRightTop]hstack[topLeftDone],

    [0:4]crop=1344:1344:1376:0[TopMiddle],

    [0:4]crop=128:1344:x=3344:y=0,format=yuvj420p,
    geq=
    lum='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    cb='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    cr='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    a='if(between(X, 0, 64), (p((X+64),Y)*(((X+1))/"$div"))+(p(X,Y)*(("$div"-((X+1)))/"$div")), p(X,Y))':
    interpolation=n,crop=64:1344:x=0:y=0,format=yuvj420p,scale=96:1344[TopcropRightBottom],
    [0:4]crop=624:1344:x=2720:y=0,format=yuvj420p[TopleftRightBottom], 
    [0:4]crop=624:1344:x=3472:y=0,format=yuvj420p[ToprightRightBottom], 
    [TopleftRightBottom][TopcropRightBottom]hstack[ToprightAll], 
    [ToprightAll][ToprightRightBottom]hstack[ToprightBottomDone],
    [topLeftDone][TopMiddle]hstack[TopleftMiddle],
    [TopleftMiddle][ToprightBottomDone]hstack[topComplete],

    [bottomComplete]crop=in_w:in_h-1:0:0[bottomCropped],
    [topComplete]crop=in_w:in_h-1:0:0[topCropped],
    [bottomCropped][topCropped]vstack[complete], 
    [complete]v360=eac:e:interp=cubic[v]" \
    -map "[v]" -map "0:a:0" -c:v libx264 -preset "$preset" -crf 23 -pix_fmt yuv420p -c:a pcm_s16le -strict -2 -f mov "$output_file"
}

exif_process() {
    exiftool -api LargeFileSupport=1 -overwrite_original \
    -XMP-GSpherical:Spherical="true" -XMP-GSpherical:Stitched="true" \
    -XMP-GSpherical:StitchingSoftware=dummy \
    -XMP-GSpherical:ProjectionType=equirectangular \
    "$(processed_name "$1")"
}

prompt_user() {
    echo ""
    echo ""
    echo "This routine will process a directory and all sub-directories, looking for MP4 files, TS files and GoPro 360 files."
    echo "The MP4 files and TS files will be transcoded into a .mov file format using a lossy process. This is both fast and efficient"
    echo ""
    echo "The 360 files you have the following options:"
    echo "1. Copy only (will copy the .360 file into the Processed directory, this is fastest but least compatible with Linux video editors)"
    echo "2. Remap & Transcode only (will transcode the 360 file into a .mov and map the file so it is a flat image, this can be opened and used in Linux video editors)."
    echo "3. Copy and Transcode (performs both of the above procedures so both files appear in the folder structure)."
    echo ""
    echo "Please select one of the above choices:"
    read -r action

    # If the action is 2 (transcode) or 3 (both), then prompt for preset
    if [ "$action" -eq 2 ] || [ "$action" -eq 3 ]; then
        echo ""
        echo "When remapping and transcoding 360 files, you may select the following h264 presets:"
        echo ""
        echo "1. Ultra Fast"
        echo "2. Very Fast"
        echo "3. Medium"
        echo "4. Slow"
        echo ""
        echo "Please select one of the above choices:"
        read -r preset_choice

        # Based on the user's choice, set the preset variable accordingly
        case $preset_choice in
            1)
                preset="ultrafast"
                ;;
            2)
                preset="veryfast"
                ;;
            3)
                preset="medium"
                ;;
            4)
                preset="slow"
                ;;
            *)
                echo "Invalid choice. Defaulting to 'medium' preset."
                preset="medium"
                ;;
        esac
    fi
}


# ... [Keep everything before the transcode function as is]

transcode_mp4() {
    local dir="$1"
    local dest="$2"
    local file
    local subdir
    local input_file
    local relative_path
    local dest_subdir
    local output_file

    # Ensure the destination directory exists
    mkdir -p "$dest"

    # Transcoding individual .mp4 or .ts files
    shopt -s nullglob
    for file in "${dir}"/*.[Mm][Pp]4 "${dir}"/*.[Tt][Ss]; do
        relative_path="${file#$dir/}"  # get the path relative to dir
        dest_subdir="$(dirname "$relative_path")"
        input_file="$file"
        output_file="${dest}/${relative_path%.*}.mov"

        # Check if destination file already exists
        if [ ! -f "$output_file" ]; then
            echo "Processing file: $input_file"
            mkdir -p "${dest}/${dest_subdir}"
            ffmpeg -i "$input_file" -c:v copy -c:a pcm_s16le "$output_file"
        else
            echo "File $output_file already exists. Skipping."
        fi
    done

    # Recursively call the function for subdirectories
    for subdir in "${dir}"/*; do
        if [ -d "$subdir" ]; then
            transcode_mp4 "$subdir" "${dest}/${subdir#$dir/}"  # Recursive call
        fi
    done
}



process_360_recursive() {
    local src="$1"
    local dest="$2"
    
    # Check and create destination directory if it doesn't exist
    [[ ! -d "$dest" ]] && mkdir -p "$dest"
    
    # Handle .360 files in the current directory
    process_360 "$src" "$dest"

    # Recursively handle subdirectories
    for subdir in "$src"/*/; do
        if [[ -d "$subdir" ]]; then
            # Compute the destination directory for this subdir
            local subdest="${dest}/${subdir#$src}"
            
            # Check and create subdestination directory if it doesn't exist
            [[ ! -d "$subdest" ]] && mkdir -p "$subdest"
            
            process_360_recursive "$subdir" "$subdest"
        fi
    done
}


process_360() {
    local src="$1"
    local dest="$2"

    pushd "$src" > /dev/null || return  # Re-enter the source directory to process .360 files

    shopt -s nullglob

    # Process .360 files
    files=(*.360)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No .360 files found in $src."
    else
        echo "${#files[@]} .360 files found in $src."
        for file in *.360; do
            echo "Processing: $file"
            if [[ $action -eq 1 || $action -eq 3 ]]; then
                cp "$file" "$dest"
            fi
            if [[ $action -eq 2 || $action -eq 3 ]]; then
                ffmpeg_process "$file" "$dest" "$preset"  # Pass the preset to ffmpeg_process
                exif_process "${dest}${file%.*}.mov"
            fi
            ((total_files_processed++))  # Increment the counter for each processed file
        done
    fi

    popd > /dev/null  # Return to the original directory
}


prompt_user
determine_destination

process_360_recursive "$(pwd)" "$dest"  # First process the .360 files recursively
transcode_mp4 "$(pwd)" "$dest"  # Then transcode the MP4 files in the main directory

echo "Total files processed: $total_files_processed"  # Print the total number of processed files

