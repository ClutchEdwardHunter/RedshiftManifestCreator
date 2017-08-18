# RedshiftManifestCreator
A ruby based utility that creates Redshift copy manifest from S3 bucket files.

Use:  It is fairly easy to setup, use the rs_manifest_config.json file to plug in your settings.

The manifest creator will look at a particular portion of an object key in the target S3 bucket, specified in the configuration key #folder_file_key, and will place any and all files it locates in the target bucket onto the manifest.

Some optional keys can be set to perform various screen output and other functions:

-- Mandatory Flag: leave this set to true unless it is okay in the manifest if a specified file cannot be located at the time your COPY command runs against Redshift.

-- Verbose Mode:  Feel like being drowned in on screen output?  This will over inform you as to what is happening.
-- Upload Manifest:  Set this to false if you don't want the manifest uploaded - by default it loads it to the root folder of the specified bucket, however, by naming your manifest with a pathname, it can be loaded there in the bucket instead.  

# Not yet working:
Support for specific extensions
Support for ARN roles
