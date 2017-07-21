# RemotePathAndUnRAR
Linux CLI Script to prepare files for Sonarr/Radarr

I created this script to solve a constant problem: Once a file was downloaded via Sonarr/Radarr to my seedbox, then synced to my local system, it was often not quite ready for Sonarr/Radarr to pick up. Some popular private torrent sites utilize RAR formats, and these files would sit, breaking my automation. I had used cron jobs to scan for RAR files and un-RAR them periodically, but that was not efficient.

This script will do the following:

1. Scan for any \*.MKV files in a specified directory
2. Copy any files found to a second directory that is monitored by Sonarr/Radarr
3. Scan for any \*.RAR files in a specified directory
4. Utilize 7z to extract the file
5. Move the extracted file to the second directory that is monitored by Sonarr/Radarr
6. Keep a detailed log of every file moved and extracted, to ensure effort is not duplicated.

Example:
Sonarr sees the newest episode of Popular TV Show S06E01 has hit the net. It grabs a torrent, and sends it to deluge. Deluge downloads the file, and using the Executor Egg, when the torrent completes it executes MoveCompleted.sh bash script. This script scans for RAR files, and sees /home/deluge/completed/Popular.TV.Show.720p.HDTV.x264-AVS/Popular.TV.Show.720p.HDTV.x264-AVS.rar pop up. It iterates through the list of RAR files it has previously extracted, and since this is new, it is not on the list. It then creates a directory in /home/deluge/sonarrcompleted titled "Popular.TV.Show.720p.HDTV.x264-AVS", un-rar's the .RAR file, then moves it to the newly created directory.
