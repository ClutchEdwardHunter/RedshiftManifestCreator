

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
DIFFOUT = @config["differential"]["active"]
DIFFMNT = DIFFOUT ? @config["differential"]["input_manifest"] : false

if VERBOSE 
	puts "RW_AKEY: #{RW_AKEY}\n"
	puts "RW_ASEC: #{RW_ASEC}\n"
	puts "AWS_REGION: #{AWS_REG}\n"
	puts "BUCKET: #{TBUCKET}\n"
	puts "FOLDER: #{FLDMASK}\n"
	puts "MANIFEST_NAME: #{MANIFST}\n"
	puts "UPLOADM: #{UPLOADM}"
	PUTS "WRITEMANIFEST: #{WMANFST}"
end

#configure aws
Aws.config.update({
  region: AWS_REG,
  credentials: Aws::Credentials.new(RW_AKEY,RW_ASEC)
})




def create_manifest(mandatory)
	s3 = Aws::S3::Resource.new
	manifest_entries = {:entries=>[]}
	puts "Targeting bucket (from config): #{TBUCKET}" if VERBOSE
	bucket=s3.bucket(TBUCKET)
	puts "Parsing bucket for items matching #{FLDMASK}" if VERBOSE
	bucket.objects.each do |obj|
		if obj.key.to_s.include? FLDMASK.to_s
		  puts "Targeting: #{obj.key}" if VERBOSE
		  output_f = "s3://#{TBUCKET}/#{obj.key}"
		  manifest_entries[:entries].push({:url=>output_f,:mandatory=>mandatory})
		  puts "Added to manifest_hash: #{{:url=>output_f,:mandatory=>mandatory}}" if VERBOSE
  	    end
    end
    manifest_entries
   
end

def write_manifest_file(manifest_entries)
	puts 'Outputting file to local system...' if VERBOSE
	File.write("#{LOCAL_PATH}/#{MANIFST}.manifest",JSON.pretty_generate(manifest_entries))
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




@current_manifest_hash = create_manifest

if WMANFST 
	write_manifest_file(JSON.pretty_generate(@current_manifest_hash)) 
else
	puts "Manifest created, but not written to disk.\nResults display:"
	puts @current_manifest_hash.inspect
end







if UPLOADM
	upload_manifest
else
	puts "Manifest upload disabled.  Manifest was not uploaded to cloud. \n"
	puts "Edit upload_manifest key in config file to enable. "
end
