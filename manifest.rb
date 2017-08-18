
require 'aws-sdk'
require 'json'


##FETCH CONFIG DATA
LOCAL_PATH = File.dirname(__FILE__)
config_file = File.read("#{LOCAL_PATH}/rs_manifest_config.json")
config_hash = JSON.parse(config_file)
@config = config_hash["manifest_config"]


#assign statics
RW_AKEY =  @config["aws_info"]["credentials"]["key"] 
RW_ASEC =  @config["aws_info"]["credentials"]["secret"]
AWS_REG =  @config["aws_info"]["bucket_info"]["target_bucket_region"]
TBUCKET =  @config["aws_info"]["bucket_info"]["target_bucket_name"]
FLDMASK =  @config["aws_info"]["bucket_info"]["folder_file_mask"]
MANIFST =  @config["manifest_name"]
VERBOSE =  @config["verbose_mode"]
UPLOADM =  @config["upload_manifest"]

if VERBOSE 
	puts "RW_AKEY: #{RW_AKEY}\n"
	puts "RW_ASEC: #{RW_ASEC}\n"
	puts "AWS_REGION: #{AWS_REG}\n"
	puts "BUCKET: #{TBUCKET}\n"
	puts "FOLDER: #{FLDMASK}\n"
	puts "MANIFEST_NAME: #{MANIFST}\n"
	puts "UPLOADM: #{UPLOADM}"
end

#configure aws
Aws.config.update({
  region: AWS_REG,
  credentials: Aws::Credentials.new(RW_AKEY,RW_ASEC)
})


#setup manifest hash / files array
@manifest = {:entries=>[]}
@files = []

def manifest_entry(file, mandatory)
	bucket = TBUCKET
	root_folder = FLDMASK
    base_url = "s3://#{TBUCKET}"
    #puts "Using base url: #{base_url}"
    output_f = "s3://#{TBUCKET}/#{file}"
	@manifest[:entries].push({:url=>output_f,:mandatory=>true})
	puts "Added to manifest_hash: #{{:url=>output_f,:mandatory=>true}}" if VERBOSE
end

def get_file_keys
	s3 = Aws::S3::Resource.new
	puts "Targeting bucket (from config): #{TBUCKET}" if VERBOSE
	bucket=s3.bucket(TBUCKET)
	puts "Parsing bucket for items matching #{FLDMASK}" if VERBOSE
	bucket.objects.each do |obj|
		if obj.key.to_s.include? FLDMASK.to_s
		  puts "Targeting: #{obj.key}" if VERBOSE
  		  manifest_entry(obj.key,"true")
  		  @files.push(obj.key)
  	    end
    end
   
end

def write_manifest_file
	puts 'Outputting file to local system...' if VERBOSE
	File.write("#{LOCAL_PATH}/#{MANIFST}.manifest",JSON.pretty_generate(@manifest))
end
def upload_manifest
	puts "Uploading manifest: #{MANIFST} to S3..." if VERBOSE
	s3 = Aws::S3::Resource.new
	obj = s3.bucket(TBUCKET).object(MANIFST)
	obj.upload_file("#{LOCAL_PATH}/#{MANIFST}.manifest")
end

get_file_keys
write_manifest_file
if UPLOADM
	upload_manifest
else
	puts "Manifest upload disabled.  Manifest was not uploaded to cloud. \n"
	puts "Edit upload_manifest key in config file to enable. "
end

