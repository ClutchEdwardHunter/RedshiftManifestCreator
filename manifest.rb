

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
WMANFST =  @config["write_manifest"]

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
	file_array = []
	puts "Targeting bucket (from config): #{TBUCKET}" if VERBOSE
	bucket=s3.bucket(TBUCKET)
	puts "Parsing bucket for items matching #{FLDMASK}" if VERBOSE
	bucket.objects.each do |obj|
		if obj.key.to_s.include? FLDMASK.to_s
		  puts "Targeting: #{obj.key}" if VERBOSE
  		  manifest_entry(obj.key,"true")
  		  
  		  #@files.push(obj.key)
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
	obj = s3.bucket(TBUCKET).object("#{MANIFST}.manifest")
	obj.upload_file("#{LOCAL_PATH}/#{MANIFST}.manifest")
end

def get_file_details(s3_obj)
	details = Hash.new
	details[:key] = s3_obj.key
	details[:size] = s3_obj.size
	details[:owner] = s3_obj.owner
	details[:last_modified] = s3_obj.last_modified
	details[:public_url] = s3_obj.public_url
	details
end


def differential_manifest(json_path_file) #take an input manifest and generate a manifest with the exceptions
	manifest = Hash.new
	input_hash = JSON.parse(File.read("#{LOCAL_PATH}/#{json_path_file}"))
	@manifest = nil #clear out and reset the manifest
	@manifest = {:entries=>[]}
	@diff = {:entries=>[]}
	get_file_keys
	@manifest[:entries].each do |entry| 
	  
	end


	return manifest
end


def generate_copy_statement
#TODO: generate copy sql
end


get_file_keys
write_manifest_file if WMANFST

=begin
if ARGV
	cmd, *arg = ARGV
	if cmd == '--d' && arg
		differntial_manifest(arg)
=end



if UPLOADM
	upload_manifest
else
	puts "Manifest upload disabled.  Manifest was not uploaded to cloud. \n"
	puts "Edit upload_manifest key in config file to enable. "
end
