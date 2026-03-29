#!/usr/bin/env ruby

require "socket"
require "webrick"

HOST = "127.0.0.1"
PREFERRED_PORTS = [4173, 4174, 4175, 8080, 8000]
ROOT = File.expand_path("..", __dir__)

def find_free_port
  PREFERRED_PORTS.each do |port|
    begin
      server = TCPServer.new(HOST, port)
      server.close
      return port
    rescue Errno::EADDRINUSE, Errno::EACCES
      next
    end
  end

  raise "空いているローカルポートが見つかりませんでした。"
end

def open_browser(url)
  return if %w[1 true yes].include?(ENV.fetch("NO_OPEN_BROWSER", "").downcase)

  ["Google Chrome", "Microsoft Edge", "Chromium"].each do |app|
    return if system("open", "-a", app, url, out: File::NULL, err: File::NULL)
  end

  system("open", url, out: File::NULL, err: File::NULL)
end

port = find_free_port
url = "http://#{HOST}:#{port}/"

mime_types = WEBrick::HTTPUtils::DefaultMimeTypes.merge(
  "webmanifest" => "application/manifest+json"
)

server = WEBrick::HTTPServer.new(
  BindAddress: HOST,
  Port: port,
  DocumentRoot: ROOT,
  MimeTypes: mime_types,
  AccessLog: [],
  Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN)
)

server.mount_proc("/") do |req, res|
  WEBrick::HTTPServlet::FileHandler.new(server, ROOT).service(req, res)
  res["Cache-Control"] = "no-store, no-cache, must-revalidate"
  res["Pragma"] = "no-cache"
  res["Expires"] = "0"
end

trap("INT") do
  puts "\nローカルサーバーを停止します。"
  server.shutdown
end

puts ""
puts "だにえるキャリブー"
puts "配信フォルダ: #{ROOT}"
puts "起動URL: #{url}"
puts "Chrome または Edge で開いてください。"
puts ""
puts "このウィンドウは作業中は閉じないでください。"
puts "終了するときは Ctrl + C を押してください。"
puts ""

open_browser(url)
server.start
