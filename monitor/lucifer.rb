#!/usr/bin/env ruby


require 'digest/sha1'
require 'dirge'
config_file = ARGV[0]

puts "Lucifer is alive: #{Time.new}"

cfg = []
cfg << "10:90:90"
cfg << "/usr/local/bin/ruby /usr/local/bin/thin start --no-epoll --threaded -R config.ru -p 8080"
cfg << "kuccello@gmail.com"
#cfg << "/usr/share/deploy/platform/OPENapps/d2/openapps-start.sh"
cfg << "nohup nice /usr/local/bin/thin start --no-epoll --threaded --port 8080 -R /usr/share/deploy/LifeForce/LifeForceTV/config.ru > /usr/share/deploy/LifeForce/LifeForceTV/lftv.out 2>&1 &"
cfg << "/usr/share/deploy/LifeForce/LifeForceTV/monitor/restart.txt"
cfg << "/usr/share/deploy/LifeForce/LifeForceTV/monitor/not-running.txt"
cfg << "/usr/share/deploy/LifeForce/LifeForceTV/monitor/cpu-too-high.txt"
cfg << "/usr/share/deploy/LifeForce/LifeForceTV/monitor/mem-too-high.txt"

cfg = File.readlines(config_file) if config_file && File.exists?(config_file)

monitor   = cfg[0] # CYCLES:MAX_CPU:MAX_MEM ... ie. 10:90:90 (if the cpu use or ram use is 90% or over for 10 consecutive checks then restart)
proc_name = cfg[1] # NAME OF THE PROC OF INTREST...  ie. "/usr/local/bin/ruby /usr/local/bin/thin start --no-epoll --threaded --port 8080 -R openapps.ru"
email_to  = cfg[2] # Semicolon seperated list of email addresses to notify if there is an issue
start_script = cfg[3] # d2;openapps-start.sh
restart_email_tpl = cfg[4]
not_running_email_tpl = cfg[5]
cpu_too_high = cfg[6]
mem_too_high = cfg[7]

cycles = 10
max_cpu = 90
max_mem = 90

mon_split = monitor.split(":")
cycles = mon_split[0].to_i if mon_split[0]
max_cpu = mon_split[1].to_i if mon_split[1]
max_mem = mon_split[2].to_i if mon_split[2]

proc_name_sha1 = Digest::SHA1.hexdigest(proc_name)
log_name = "/usr/share/deploy/LifeForce/LifeForceTV/monitor/#{proc_name_sha1}.log"


def send_email(who,which,msg,proc_n="")

  proc_name_sha1 = Digest::SHA1.hexdigest(proc_n)
  log_name = "/usr/share/deploy/LifeForce/LifeForceTV/monitor/#{proc_name_sha1}.log"

  email = nil
  File.open(which,'r') do |file|
    tpl = file.read
    email = tpl.sub(/TO_REPLACE/,who).sub(/MSG_REPLACE/,msg).sub(/PROC_REP/,proc_n)
  end
  stamp = Time.new.to_i.to_s
  temp_email = "/usr/share/deploy/LifeForce/LifeForceTV/monitor/#{proc_n||'nil'}_#{stamp}.email"
  File.open(temp_email,'w') do |eml|
    eml.write(email) if email
  end
# puts "sendmail #{who.strip} < #{temp_email}"
  `/usr/sbin/sendmail #{who.strip} < #{temp_email}`
  # `cp #{log_name} #{log_name}.previous_log`
  #  begin
  #    `/bin/tar -czf /usr/share/deploy/platform/OPENapps/d2/openapps.tgz /usr/share/deploy/platform/OPENapps/d2/openapps.out #{log_name}; /bin/cat /usr/share/deploy/platform/OPENapps/d2/openapps.tgz | uuencode /usr/share/deploy/platform/OPENapps/d2/openapps.tgz | sendmail -flucifer@p1.openapps.com -F"Lucifer Script" #{who.strip}`
  #  rescue => e
  #    puts "#{__FILE__}:#{__LINE__} #{__method__} OPPS: could not send file because: #{e} -- #{e.backtrace}"
  #  end
 
end


unless File.exists?(log_name) then
  # need to create the file
  system "touch #{log_name}"
end

found_proc = false
matched_proc = nil
result = `ps -eo %cpu,%mem,pid,cmd`.split("\n")
result.shift
result.each do |proc_line|
  proc_data = {}
  sections = proc_line.strip.split(/\s+/)
  cpu = sections.shift
  proc_data[:cpu] = cpu
  mem = sections.shift
  proc_data[:mem] = mem
  pid = sections.shift
  proc_data[:pid] = pid
  cmd = sections.join(" ")
  proc_data[:cmd] = cmd
  if cmd.strip == proc_name.strip then
    matched_proc = proc_data
    puts "MATCHED! WE FOUND THE PROC!"
    found_proc = true
    hist_file = File.readlines("/usr/share/deploy/LifeForce/LifeForceTV/monitor/#{proc_name_sha1}.log")
    File.open("/usr/share/deploy/LifeForce/LifeForceTV/monitor/#{proc_name_sha1}.log",'w') do |file|
      file.puts proc_line
      cycles_minus_one = cycles - 2 # need to actually subtract 2 because of the zero index below
      hist_file[0..cycles_minus_one].each do |line|
        file.puts line
      end
    end
  end
end


hist_file = File.readlines("/usr/share/deploy/LifeForce/LifeForceTV/monitor/#{proc_name_sha1}.log")

# do we have sufficient history to make a judgement?
if hist_file.size >= cycles then

  cpu_total = 0.0
  mem_total = 0.0
  hist_file.each do |proc_line|
    sections = proc_line.strip.split(/\s+/)
    cpu = sections.shift
    mem = sections.shift

    cpu_total += cpu.to_f
    mem_total += mem.to_f
  end

  cpu_avg = cpu_total / hist_file.size
  mem_avg = mem_total / hist_file.size

  if cpu_avg >= max_cpu.to_f then
    # ALERT!!! CPU IS MAXING OUT!! PANIC PANIC PANIC!!!! -- SEND EMAILS AND RESTART THE PROC
    msg = "CPU IS AVERAGING #{cpu_avg} over #{cycles} cycles"
    `kill -9 #{matched_proc[:pid]}`
    `#{start_script}`
    send_email(email_to,cpu_too_high,msg,matched_proc[:cmd])
  end

  if mem_avg >= max_mem.to_f then
    # ALERT!!! MEMORY IS MAXING OUT!! PANIC PANIC PANIC!!!! -- SEND EMAILS AND RESTART THE PROC
    msg = "MEM IS AVERAGING #{mem_avg} over #{cycles} cycles"
    `kill -9 #{matched_proc[:pid]}`
    `#{start_script}`
    send_email(email_to,mem_too_high,msg,matched_proc[:cmd])
  end
else
  puts "WAITING FOR ENOUGH INFO... CYCLES: #{cycles} --- LINES: #{hist_file.size}"
end

unless found_proc then
  puts "ALERT!!! - PROCESS NOT RUNNING!! --[ #{proc_name} ]"
  # should send emails out
  send_email(email_to,not_running_email_tpl,"THE PROCESS: #{proc_name} WAS NOT RUNNING!!!")
  # should start the process
  `#{start_script}`
end
