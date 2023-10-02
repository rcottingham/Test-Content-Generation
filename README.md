# Test-Content-Generation

## Overview

This repository provides the information and scripts to generate the CTA Wave Test Content.

The ```run-all.py profiles/csv_file``` script gathers the data and content from input tables/parameters. Then it sends them for processing. Then it uploads the result.

The ```encode_dash.py``` script is primarily about the usage of [GPAC](http://gpac.io) leveraging libavcodec with x264 and x265 to generate the CMAF content with some DASH manifest. The intent is to keep the size of the post-processing (e.g. manifest manipulation) as small as possible.

## Workflow

* Download mezzanine content from https://dash.akamaized.net/WAVE/Mezzanine/. See section below for a script.
* Launch scripts:
  * Encode mezzanine content:
    * Encode to conform to CTA Proposed Test content.
    * Encode at least one option of source content according to media profile.
    * Special codec value "copy" to bypass the encoding. Useful for proprietary codecs such as DTS or Dolby.
  * Package (markup) the content with an MPD according to the CTA Content Model format.
    * NB: done in Python right now, but could eventually an extension to [GPAC](http://gpac.io) to produce this.
  * Encrypt the content in-place using [GPAC](http://gpac.io) encryption and manifest-forwarding capabilities.
  * Upload the proposed test content to the CTA-WAVE server using SFTP.
  * Update the Webpage: update [database.json](https://github.com/cta-wave/Test-Content/blob/master/database.json).
    * NB: updates and merges are [done manually](https://github.com/cta-wave/Test-Content-Generation/issues/45).
    * NB: the Web page code is located at https://github.com/cta-wave/Test-Content/.
    * NB: when the JSON format needs to be updated, open an issue at https://github.com/cta-wave/dpctf-deploy/issues/.
* Validate that the content conforms to:
  * Its own constraints and flags. [Script](https://github.com/nicholas-fr/test-content-validation/).
  * CMAF: use the [DASH-IF hosted conformance tool](https://conformance.dashif.org/).
  * CTA WAVE Test content format **needs to be extended to format validation**
 
## Downloading mezzanine

Sample script for mezzanine v4:
```
mkdir -p releases/4
cd releases/4
curl http://dash.akamaized.net/WAVE/Mezzanine/releases/4/| sed -n 's/^<IMG SRC=\"\/icons\/generic.gif\" ALT=\"\[FILE\]\"> <A HREF=\"\(.*\)\".*$/\1/p' | grep -v croatia_M1 | grep -v croatia_N1 | grep -v croatia_O1 | xargs -I % wget http://dash.akamaized.net/WAVE/Mezzanine/releases/4/%
cd ..
```

## Encoding to test content
 
* Content and encoding options are documented here for AVC:
  * https://docs.google.com/spreadsheets/d/1hxbqBdJEEdVIDEkpjZ8f5kvbat_9VGxwFP77AXA_0Ao/edit#gid=0
  * https://github.com/cta-wave/Test-Content-Generation/issues/13
  * https://github.com/cta-wave/Test-Content-Generation/wiki/CFHD-Test-Streams
  
## How to generate the content

### Main content (clear and encrypted)

* Modify ```run-all.py``` to:
  * Modify the [executable locations, input and output files location, codec media profile, framerate family](run-all.py) to match your own.
  * Make sure the DRM.xml file is accessible from the output folder.
  * Inspect the input list e.g. ([default](profiles/avc.csv)).
* Run ```./run-all.py csv_file``` (with optionally your custom csv file as an argument), and grab a cup of tea (or coffee).

### Switching Set X1 (ss1)

The generation of current [Switching Sets (ss1 for avc, ss2 for hevc/chh1)](https://github.com/cta-wave/Test-Content-Generation/issues/60) is done by executing ```ss/gen_ss1.sh``` and ```ss/gen_ss2.sh```.

### Splicing tests

The generation of current [splicing tests](https://github.com/cta-wave/Test-Content/issues/19) is done by executing ```splice/gen_avc.sh``` and ```splice/gen_hevc_chh1.sh```.

### Chunked tests

The generation of current [chunked tests](https://github.com/cta-wave/Test-Content/issues/41) is done by executing ```chunked/gen.sh cfhd t16``` and ```chunked/gen.sh chh1 t2```.

### Audio content (XPERI/DTS)

Comment/uncomment the ```inputs``` array entries in ```run-all.py```. Then ```./run-all.py profiles/dtsc.csv``` to generate the ```dtsc``` content.

## Validation

Validation as of today is done manually. 

The process of validation includes:

- A initial phase checking that required parameters according to the test content description are applied:
  - Media: https://github.com/nicholas-fr/test-content-validation
  - CMAF and manifests: TODO
- An API call to the [DASH-IF conformance validator](http://conformance.dashif.org) is [done](https://github.com/nicholas-fr/test-content-validation) to check against MPD and CMAF conformance for CTA WAVE test content. Some conformance [reported issues](https://github.com/cta-wave/Test-Content-Generation/issues/55) remain.
- The content should be amended with a conformance check output document: [TODO](https://github.com/cta-wave/Test-Content/issues/49).

## AAC Audio
The steps to generate content are:
1. Encoding
2. Dashing
3. Patching isobmff
4. Patching MPD for CTA
 
**Pre-requisites**
1. **ffmpeg with libfdk_aac** should be installed.
2. The latest version of **gpac** should be installed.
3. Download mezzanine content from https://dash.akamaized.net/WAVE/Mezzanine/.
 
### 1. Encoding
To encode the media ffmpeg is used. The command used differs depending on the codec.
 
**For AAC-LC**
For aac-lc the ffmpeg command used is:
```
ffmpeg -i {​​source}​​​​​​​​​ -c:a libfdk_aac aac_lc -ar {​​​​​​​​​​​​​​​​Sample Rate}​​​​​​​​​​​​​​​​ -b:a {​​​​​​​​​​​​​​​​Bitrate}​​​​​​​​​​​​​​​​ {​​​​​​​​​​​​​​​​channel_config}​​​​​​​​​​​​​​​​ -t {​​​​​​​​​​​​​​​​Duration}​​​​​​​​​​​​​​​​ -use_editlist {​​​​​​​​​​​​​​​​elst_present}​​​​​​​​​​​​​​​​ {​​​​​​​​​​​​​​​​output1}​​​​​​​​​​​​​​​​.mp4
```
**For HE-AAC or HE-AAC-V2**
For he-aac or he-aac-v2 the ffmpeg command used is:
```
ffmpeg -i {​​​​​​​​​​​​​​​​source}​​​​​​​​​​​​​​​​ -c:a libfdk_aac -profile:a {​​​​​​​​​​​​​​​​codec}​​​​​​​​​​​​​​​​ -ar {​​​​​​​​​​​​​​​​Sample Rate}​​​​​​​​​​​​​​​​ -frag_duration 1963000 -flags2 local_header -latm 1 -header_period 44 -signaling 1 -movflags empty_moov -movflags delay_moov -b:a {​​​​​​​​​​​​​​​​Bitrate}​​​​​​​​​​​​​​​​ {​​​​​​​​​​​​​​​​channel_config}​​​​​​​​​​​​​​​​ -t {​​​​​​​​​​​​​​​​Duration}​​​​​​​​​​​​​​​​ -use_editlist {​​​​​​​​​​​​​​​​elst_present}​​​​​​​​​​​​​​​​ {​​​​​​​​​​​​​​​​output1}​​​​​​​​​​​​​​​​.mp4
```
**For encrypted**
If media is to be encrypted, it should be done with prefered tool before dashing. Mp4box supports encrypting media.
 
### 2. Dashing
To dash the content gpac is used:
```
gpac -i {​​​​​​​​​​​​​​​​output1}​​​​​​​​​​​​​​​​.mp4:FID=A1 -o {​​​​​​​​​​​​​​​​output2}​​​​​​​​​​​​​​​​.mpd:profile=live:muxtype=mp4:segdur={​​​​​​​​​​​​​​​​segmentduration}​​​​​​​​​​​​​​​​:cmaf=cmf2:stl:tpl:template="1/$Time$":SID=A1'
```
 
### 3. Patching isobmff
To patch the isobmff an internal script is used. An example of what needs to be changed is:
1. styp compatbility brands needs set to ["msdh", "msix", "cmfs", "cmff", "cmf2", "cmfc", "cmf2"]
 
### 4. Patching mpd for CTA
To patch the mpd an internal script is used. The changes that are made are defined in the CTA WAVE Specification **Content Model Format for Single Media Profile**. An example of a change the mpd requires is:
1. adding copyright notice
 
### 5. Validate the content:
To validate the content the steps below should be used:
1. Use the DASH-IF tool https://conformance.dashif.org/
2. Manual checks that are documents in section 2.



Check **codecs**:
1. Open MPD
2. Compare codec from MPD to the table found in WAVE spec

Check **segment size**:
1. Open MPD
2. Search for maxSegmentDuration
3. Compare with Segment Duration in aac.csv file
 
Check **chunks per segment**:
1. Navigate to folder containing all of the segments.
2. Open cmd
3. Run mp4dump --format json <segment_name>.m4s
4. Count the number of chunks within each segment. (1 moof-mdat pair = 1 chunk)
5. Repeat process for 3-4 segments to make sure it is correct.
 
Check **duration**:
1. Open cmd in the directory where the mp4 is located
2. Run ffprobe -hide_banner -print_format json -show_streams <encoded>.mp4
3. Search for duration
 
Check **sample rate**:
1. Open cmd in the directory where the mp4 is located
2. Run ffprobe -hide_banner -print_format json -show_streams <encoded>.mp4
3. Search for sample rate
 
Check **channels**:
1. Open cmd in the directory where the mp4 is located
2. Run ffprobe -hide_banner -print_format json -show_streams <encoded>.mp4
3. Search for channels
 
Check **bitrate**:
1. Open cmd in the directory where the mp4 is located
2. Run ffprobe -hide_banner -print_format json -show_streams <encoded>.mp4
3. Search for bitrate
 
Check **trun version**:
1. Open trun_version.py
2. Change input path to .m4s contained in the media you are testing
3. Run code on 3 different segments
 
Check edit list:
1. Open cmd in directory where init.mp4 is located
2. run mp4dump --verbosity 3 --format json init.mp4
3. Search for edts. If it is present is passed the test
If encrypted...TBA
 
Check all 3 offsets are aligned:
1. Install sonic visualiser
3. Drag .mp4 (found in the encoded folder)
4. Measure the offset (offset_from_visualiser)
5. Open cmd and run run mp4dump --verbosity 3 --format json init.mp4
6. Search for "entry/media time"
7. Calculate the offset by using this formula: (entry/media time)/bitrate
8. Compare the offset_from_visualiser and the offset from step 7 if they are the same then it passed the test.
 
Duration calculated from segments:
1. go to last segment
2. run mp4dump --verbosity 3 --format json <final_segment.m4s>
3. take "base media decode time"
4. add samples
5. check offset from init file (Total_sample_size - offset)/samplerate = should be close to the media duration in CSV file
 
Duration matches:
MUST BE IN +-50MS from previous section if not answer is NO
 
Duration in mpd:
mediaPresentationDuration compare to duration in CSV file
 
Encoded mp4 playback test:
1. play the mp4 file on VLC
 
Concatenated mp4 test:
IF NO ENCRYPTION:
1. go to file with segments
2. use script to concatenate segments into mp4.file then run mp4 file on VLC to check if it works
3. run output in VLC
NOTE: can use "dir /b > filenames.txt" to quickly copy all names in folder
 
IF ENCRYPTION:
1. go to file with segments
2. use script to concatenate segments into mp4.file
3. Place cenc.xml folder in the same directory (found in fraunhofer_wave)
4. gpac -i <filename>.mp4 cdcrypt:cfile=cenc.xml -o out.mp4
5. run output in VLC
 
Check audio sap types for segments:
1- Run copy /b init.mp4 + seg.m4s output.mp4
2- Run gpac -i output.mp4 inspect:deep:analyze=on > sap.txt
3- Open sap.txt and look at sap values
Note: segments should have a sap value of 1
 
Check if SBR explicit (only applies to heaac and heaacv2)
1- open output.mp4 from previous step in in media info
2- got to text view
3- if HE-AAC check it has values
 
Format: AAC LC SBR
Commercial name: HE-AAC
Format settings: Explicit
 
4- if HE-AACv2 check it has values
 
Format: AAC LC SBR PS
Commercial name: HE-AACv2
Format settings: Explicit
 
### Update the Webpage: update database.json.
Once new content is generated is must be added to the test runner. The steps below are used:
1. Updates and merges are done manually.
2. The Web page code is located at https://github.com/cta-wave/Test-Content/.
3. When the JSON format needs to be updated, open an issue at https://github.com/cta-wave/dpctf-deploy/issues/

