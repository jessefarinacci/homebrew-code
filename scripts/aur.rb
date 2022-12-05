#!/usr/bin/env ruby

# this script needs phetch-aur to exist locally, which should be
# handled by the Makefile in this repo.

# it also needs a remote arch box called "archdev" in ~/.ssh/config
# that it can clone phetch-aur into.

version = ENV['VERSION'].to_s
if version.empty?
    warn "Need env VERSION=vX.X.X"
    exit 1
end

def cmd(s)
    puts ">> #{s}"
    `#{s}`
end

pkgbuild = File.read("phetch-aur/PKGBUILD")

count = pkgbuild[/pkgrel=(.+)/, 1].to_i
pkgbuild.sub!("pkgrel=#{count}", "pkgrel=1")

oldver = pkgbuild[/pkgver=(.+)/, 1]
pkgbuild.sub!("pkgver=#{oldver}", "pkgver=#{version.sub('v','')}")

File.open('PKGBUILD.new', 'w') { |f| f.puts pkgbuild }

cmd "ssh archdev 'git clone https://aur.archlinux.org/phetch.git phetch-aur'"
cmd "ssh archdev 'cd phetch-aur && git clean -fd && git checkout . && git pull'"
cmd "scp PKGBUILD.new archdev:~/phetch-aur/PKGBUILD"
cmd "ssh archdev 'cd phetch-aur && makepkg'"
cmd "rm -f PKGBUILD.new"

newsha = cmd("ssh archdev 'sha256sum phetch-aur/phetch-#{version.sub('v','')}.tar.gz'").split(' ').first
oldsha = pkgbuild[/sha256sums=(.+)/, 1]
pkgbuild.sub!("sha256sums=#{oldsha}", "sha256sums=('#{newsha}')")

cmd "cd phetch-aur && makepkg --printsrcinfo > .SRCINFO"

File.open('phetch-aur/PKGBUILD', 'w') { |f| f.puts pkgbuild }
