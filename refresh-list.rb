#!/usr/bin/env ruby

require "rest-client"
require "fileutils"

require "digest/md5"
require "digest"

$debug = 0

def valid_checksum(checksum, checksum_string)
  if checksum_string =~ /^[a-f0-9]+$/
    return true if (checksum == "md5" and checksum_string.size == 32) or (checksum == "sha1" and checksum_string.size == 40) or (checksum == "sha256" and checksum_string.size == 64) or (checksum == "sha512" and checksum_string.size == 128)
  end

  return flase
end

allowed_checksums = ["md5", "sha1", "sha512", "sha256"]

def getfile(src_url)
  begin
    resp = RestClient.get(src_url)
  rescue => e
    STDERR.puts(e)
    STDERR.puts(e.inspect)
    STDERR.puts("Error fetching URL: #{src_url}")
    exit 2
  end
  return resp
end

def digestfile(hash, filename)
  if filename.nil?
    STDERR.puts("File doesn't exist \"#{filename}\"")
    exit 1
  end

  case hash.upcase
  when "MD5"
    md5 = Digest::MD5.file(filename)
    return md5.hexdigest
  when "SHA1"
    sha1 = Digest::SHA1.file(filename)
    return sha1.hexdigest
  when "SHA256"
    sha256 = Digest::SHA256.file(filename)
    return sha256.hexdigest
  when "SHA512"
    sha512 = Digest::SHA512.file(filename)
    return sha512.hexdigest
  else
    md5 = Digest::MD5.file(filename)
    return md5.hexdigest
  end
end

def digestresp(hash, resp)
  if resp.nil?
    STDERR.puts("Response is nil")
    exit 1
  end

  case hash.upcase
  when "MD5"
    md5 = Digest::MD5.new
    md5.update(resp)
    return md5.hexdigest
  when "SHA1"
    sha1 = Digest::SHA1.new
    sha1.update(resp)
    return sha1.hexdigest
  when "SHA256"
    sha256 = Digest::SHA256.new
    sha256.update(resp)
    return sha256.hexdigest
  when "SHA512"
    sha512 = Digest::SHA512.new
    sha512.update(resp)
    return sha512.hexdigest
  else
    md5 = Digest::MD5.new
    md5.update(resp)
    return md5.hexdigest
  end
end

checksum = ARGV[0].downcase

dest_filename = ARGV[1]
src_url = ARGV[2]

if !allowed_checksums.include?(checksum)
  STDERR.puts("Wrong checksum: #{checksum}")
  exit 20
end

if !File.file?(dest_filename)
  STDERR.puts("File doesn't exist \"#{dest_filename}\"")
  exit 1
end

current_file_checksum = ""

if !File.file?("#{dest_filename}.#{checksum}")
  STDERR.puts("Checksum File doesn't exist, Creating: \"#{dest_filename}.#{checksum}\"")
  current_file_checksum = digestfile(checksum, dest_filename)
  File.write("#{dest_filename}.#{checksum}", current_file_checksum + "\n")
else
  current_file_checksum = File.readlines("#{dest_filename}.#{checksum}")[0].strip.chomp
end

# check if the current file digeste is valid
if valid_checksum(checksum, current_file_checksum)
  STDERR.puts("Valid checksum signature in file") if $debug > 0
else
  STDERR.puts("INVALID checksum: #{current_file_checksum} !=  #{checksumsregex} , Current size #{current_file_checksum.size}")
  exit 6
end

temp_filename = "#{dest_filename}.down"

if File.file?(temp_filename)
  STDERR.puts("File exist \"#{dest_filename}\" , probaby another download in progress")
  exit 4
end

resp = getfile(src_url)
url_checksum = digestresp(checksum, resp.body)

if current_file_checksum != url_checksum
  # Write file
  File.write(temp_filename, resp.body)
  # swap files
  FileUtils.mv(temp_filename, dest_filename)

  # update checksum file
  File.write("#{dest_filename}.#{checksum}", url_checksum + "\n")
  STDERR.puts("Swapped the old to new vesrion of the file. OLD Checksum => #{current_file_checksum} , NEW Checksum => #{url_checksum}")
  exit 0
else
  STDERR.puts("File was not changed")
  exit 7
end
