#  Phusion Passenger - https://www.phusionpassenger.com/
#  Copyright (c) 2010-2013 Phusion
#
#  "Phusion Passenger" is a trademark of Hongli Lai & Ninh Bui.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

module PhusionPassenger

class NativeSupportLoader
	def self.supported?
		return !defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby" || RUBY_ENGINE == "rbx"
	end

	def try_load
		if defined?(NativeSupport)
			return true
		else
			load_from_native_support_output_dir ||
			load_from_buildout_dir ||
			load_from_load_path ||
			load_from_home_dir
		end
	end
	
	def start
		if ENV['PASSENGER_USE_RUBY_NATIVE_SUPPORT'] == '0'
			STDERR.puts " --> Continuing without #{library_name}."
			STDERR.puts "     Because PASSENGER_USE_RUBY_NATIVE_SUPPORT is set to 0."
			return false
		elsif try_load
			return true
		elsif compile_and_load || download_binary_and_load
			STDERR.puts " --> #{library_name} successfully loaded."
			return true
		else
			STDERR.puts " --> Continuing without #{library_name}."
			return false
		end
	end

private
	def archdir
		@archdir ||= begin
			PhusionPassenger.require_passenger_lib 'platform_info/binary_compatibility'
			PlatformInfo.ruby_extension_binary_compatibility_id
		end
	end
	
	def libext
		@libext ||= begin
			PhusionPassenger.require_passenger_lib 'platform_info/operating_system'
			PlatformInfo.library_extension
		end
	end
	
	def home
		@home ||= begin
			require 'etc' if !defined?(Etc)
			home = Etc.getpwuid(Process.uid).dir
		end
	end
	
	def library_name
		return "passenger_native_support.#{libext}"
	end
	
	def extconf_rb
		File.join(PhusionPassenger.ruby_extension_source_dir, "extconf.rb")
	end
	
	def load_from_native_support_output_dir
		# Quick workaround for people suffering from
		# https://code.google.com/p/phusion-passenger/issues/detail?id=865
		output_dir = ENV['PASSENGER_NATIVE_SUPPORT_OUTPUT_DIR']
		if output_dir && !output_dir.empty?
			begin
				return load_native_extension("#{output_dir}/#{VERSION_STRING}/#{archdir}/#{library_name}")
			rescue LoadError
				return false
			end
		else
			return false
		end
	end
	
	def load_from_buildout_dir
		if PhusionPassenger.buildout_dir
			begin
				return load_native_extension("#{PhusionPassenger.buildout_dir}/ruby/#{archdir}/#{library_name}")
			rescue LoadError
				return false
			end
		else
			return false
		end
	end
	
	def load_from_load_path
		return load_native_extension('passenger_native_support')
	rescue LoadError
		return false
	end
	
	def load_from_home_dir
		begin
			return load_native_extension("#{home}/#{USER_NAMESPACE_DIRNAME}/native_support/#{VERSION_STRING}/#{archdir}/#{library_name}")
		rescue LoadError
			return false
		end
	end

	def download_binary_and_load
		if !PhusionPassenger.installed_from_release_package?
			return
		end
		if ENV['PASSENGER_DOWNLOAD_NATIVE_SUPPORT_BINARY'] == '0'
			STDERR.puts " --> Skipping downloading of precompiled #{library_name}"
			return
		end

		STDERR.puts " --> Downloading precompiled #{library_name} for the current Ruby interpreter..."
		STDERR.puts "     (set PASSENGER_DOWNLOAD_NATIVE_SUPPORT_BINARY=0 to disable)"
		
		require 'shellwords'
		require 'logger'
		PhusionPassenger.require_passenger_lib 'platform_info/ruby'
		PhusionPassenger.require_passenger_lib 'utils/tmpio'
		PhusionPassenger.require_passenger_lib 'utils/download'

		PhusionPassenger::Utils.mktmpdir("passenger-native-support-") do |dir|
			Dir.chdir(dir) do
				basename = "rubyext-#{archdir}.tar.gz"
				if !download(basename, dir, :total_timeout => 30)
					return false
				end

				s_basename = Shellwords.escape(basename)
				sh "tar xzf #{s_basename}"
				sh "rm -f #{s_basename}"
				STDERR.puts "     Checking whether downloaded binary is usable..."

				File.open("test.rb", "w") do |f|
					f.puts(%Q{
						require File.expand_path('passenger_native_support')
						f = File.open("test.txt", "w")
						PhusionPassenger::NativeSupport.writev(f.fileno, ["hello", "\n"])
					})
				end

				if sh_nonfatal("#{PlatformInfo.ruby_command} -I. test.rb") &&
				   File.exist?("test.txt") &&
				   File.read("test.txt") == "hello\n"
					STDERR.puts "     Binary is usable."
					File.unlink("test.rb")
					File.unlink("test.txt")
					result = try_directories(installation_target_dirs) do |target_dir|
						files = Dir["#{dir}/*"]
						STDERR.puts "     Installing " + files.map{ |n| File.basename(n) }.join(' ')
						FileUtils.cp(files, target_dir)
						load_result = load_native_extension("#{target_dir}/#{library_name}")
						[load_result, false]
					end
					return result
				else
					STDERR.puts "     Binary is not usable."
					return false
				end
			end
		end
	end

	def compile_and_load
		if ENV['PASSENGER_COMPILE_NATIVE_SUPPORT_BINARY'] == '0'
			STDERR.puts " --> Skipping compiling of #{library_name}"
			return false
		end

		if PhusionPassenger.natively_packaged? && !File.exist?(PhusionPassenger.ruby_extension_source_dir)
			PhusionPassenger.require_passenger_lib 'constants'
			STDERR.puts " --> No #{library_name} found for current Ruby interpreter."
			case PhusionPassenger.native_packaging_method
			when 'deb'
				STDERR.puts "     This library provides various optimized routines that make"
				STDERR.puts "     #{PhusionPassenger::PROGRAM_NAME} faster. Please run 'sudo apt-get install #{PhusionPassenger::DEB_DEV_PACKAGE}'"
				STDERR.puts "     so that #{PhusionPassenger::PROGRAM_NAME} can compile one on the next run."
			when 'rpm'
				STDERR.puts "     This library provides various optimized routines that make"
				STDERR.puts "     #{PhusionPassenger::PROGRAM_NAME} faster. Please run 'sudo yum install #{PhusionPassenger::RPM_DEV_PACKAGE}-#{PhusionPassenger::VERSION_STRING}'"
				STDERR.puts "     so that #{PhusionPassenger::PROGRAM_NAME} can compile one on the next run."
			else
				STDERR.puts "     #{PhusionPassenger::PROGRAM_NAME} can compile one, but an extra package must be installed"
				STDERR.puts "     first. Please ask your operating system vendor for instructions."
			end
			return false
		end

		STDERR.puts " --> Compiling #{library_name} for the current Ruby interpreter..."
		STDERR.puts "     (set PASSENGER_COMPILE_NATIVE_SUPPORT_BINARY=0 to disable)"
		STDERR.puts "     -------------------------------"

		require 'fileutils'
		require 'shellwords'
		PhusionPassenger.require_passenger_lib 'platform_info/ruby'
		
		target_dir = compile(installation_target_dirs)
		if target_dir
			return load_native_extension("#{target_dir}/#{library_name}")
		else
			return false
		end
	end

	def installation_target_dirs
		target_dirs = []
		if (output_dir = ENV['PASSENGER_NATIVE_SUPPORT_OUTPUT_DIR']) && !output_dir.empty?
			target_dirs << "#{output_dir}/#{VERSION_STRING}/#{archdir}"
		end
		if PhusionPassenger.buildout_dir
			target_dirs << "#{PhusionPassenger.buildout_dir}/ruby/#{archdir}"
		end
		target_dirs << "#{home}/#{USER_NAMESPACE_DIRNAME}/native_support/#{VERSION_STRING}/#{archdir}"
		return target_dirs
	end

	def download(name, output_dir, options = {})
		logger = Logger.new(STDERR)
		logger.level = Logger::WARN
		logger.formatter = proc do |severity, datetime, progname, msg|
			msg.gsub(/^/, "     ") + "\n"
		end
		sites = PhusionPassenger.binaries_sites
		sites.each_with_index do |site, i|
			if real_download(site, name, output_dir, logger, options)
				logger.warn "Download OK!" if i > 0
				return true
			elsif i != sites.size - 1
				logger.warn "Trying next mirror..."
			end
		end
		return false
	end

	def real_download(site, name, output_dir, logger, options)
		url = "#{site[:url]}/#{VERSION_STRING}/#{name}"
		filename = "#{output_dir}/#{name}"
		real_options = options.merge(
			:cacert => site[:cacert],
			:use_cache => true,
			:logger => logger
		)
		return PhusionPassenger::Utils::Download.download(url, filename, real_options)
	end
	
	def mkdir(dir)
		begin
			STDERR.puts "     # mkdir -p #{dir}"
			FileUtils.mkdir_p(dir)
		rescue Errno::EEXIST
		end
	end
	
	def sh(command_string)
		if !sh_nonfatal(command_string)
			raise "Could not compile #{library_name} (\"#{command_string}\" failed)"
		end
	end

	def sh_nonfatal(command_string)
		STDERR.puts "     # #{command_string}"
		PhusionPassenger::Utils.mktmpdir("passenger-native-support-") do |tmpdir|
			s_tmpdir = Shellwords.escape(tmpdir)
			result = system("#{command_string} >#{s_tmpdir}/log 2>&1")
			system("cat #{s_tmpdir}/log | sed 's/^/     /' >&2")
			return result
		end
	end
	
	def compile(target_dirs)
		try_directories(target_dirs) do |target_dir|
			result =
				sh_nonfatal("#{PlatformInfo.ruby_command} #{Shellwords.escape extconf_rb}") &&
				sh_nonfatal("make clean && make")
			if result
				STDERR.puts "     Compilation succesful."
				[target_dir, false]
			else
				STDERR.puts "     Compilation failed."
				[nil, false]
			end
		end
	end

	def try_directories(dirs)
		result = nil
		dirs.each_with_index do |dir, i|
			begin
				mkdir(dir)
				File.open("#{dir}/.permission_test", "w").close
				File.unlink("#{dir}/.permission_test")
				STDERR.puts "     # cd #{dir}"
				Dir.chdir(dir) do
					result, should_retry = yield(dir)
					return result if !should_retry
				end
			rescue Errno::EACCES
				# If we encountered a permission error, then try
				# the next target directory. If we get a permission
				# error on the last one too then propagate the
				# exception.
				if i == dirs.size - 1
					STDERR.puts "     Encountered permission error, " +
						"but no more directories to try. Giving up."
					STDERR.puts "     -------------------------------"
					return nil
				else
					STDERR.puts "     Encountered permission error, " +
						"trying a different directory..."
					STDERR.puts "     -------------------------------"
				end
			rescue Errno::ENOTDIR
				# This can occur when locations.ini set buildout_dir
				# to an invalid path. Just ignore this error.
				if i == dirs.size - 1
					STDERR.puts "     Not a valid directory, " +
						"but no more directories to try. Giving up."
					STDERR.puts "     -------------------------------"
					return nil
				else
					STDERR.puts "     Not a valid directory. Trying a different one..."
					STDERR.puts "     -------------------------------"
				end
			end
		end
	end

	def load_native_extension(name_or_filename)
		# If passenger_native_support.so exited because it detected that it was compiled
		# for a different Ruby version, then subsequent require("passenger_native_support")
		# calls will do nothing. So we remove passenger_native_support from $LOADED_FEATURES
		# to force it to be loaded.
		$LOADED_FEATURES.reject! { |fn| File.basename(fn) == library_name }
		begin
			require(name_or_filename)
			return defined?(PhusionPassenger::NativeSupport)
		rescue LoadError => e
			if e.to_s =~ /dlopen/
				# Print dlopen failures. We're not interested in any other
				# kinds of failures, such as file-not-found.
				puts e.to_s.gsub(/^/, "     ")
			end
			return false
		end
	end
end

end # module PhusionPassenger

if PhusionPassenger::NativeSupportLoader.supported?
	PhusionPassenger::NativeSupportLoader.new.start
end