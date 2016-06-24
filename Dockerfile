FROM base/archlinux:latest
MAINTAINER Samuel Bernard "samuel.bernard@s4m.io"

# Let's run stuff
RUN \
  # First, update everything (start by keyring and pacman)
  pacman -Sy && \
  pacman -S archlinux-keyring --noconfirm --noprogressbar --quiet && \
  pacman -S pacman --noconfirm --noprogressbar --quiet && \
  pacman-db-upgrade && \
  pacman -Su --noconfirm --noprogressbar --quiet && \

  # Install useful packages
  pacman -S sudo --noconfirm --noprogressbar --quiet && \

  # Install what is needed for building native extensions
  pacman -S gcc make --noconfirm --noprogressbar --quiet && \

  # Install Ruby 2.1 and add symbolic link to binaries
  pacman -S ruby2.1 --noconfirm --noprogressbar --quiet && \
  for bin in $(ls /opt/ruby2.1/bin | grep -v '\-2\.1'); do \
    ln -s /opt/ruby2.1/bin/$bin /usr/bin/$bin; \
  done && \

  # Install Chef from gems. Force rack to be 1.6.4 for ruby 2.1 support
  gem install rack --version 1.6.4 --no-user-install --no-rdoc --no-ri && \
  gem install chef --no-user-install --no-rdoc --no-ri && \

  # Add a symbolic link for every binaries (gems we just installed)
  for bin in $(ls /opt/ruby2.1/bin); do \
    ln -s /opt/ruby2.1/bin/$bin /usr/bin/$bin -f; \
  done && \

  # Generate locale en_US (workaround for a strange bug in berkshelf)
  locale-gen en_US.UTF-8 && \

  # Time to clean
  pacman -Rs gcc make --noconfirm --noprogressbar && \
  pacman -Scc --noconfirm --noprogressbar --quiet && \

  # Mask systemd units which will fail
  systemctl mask tmp.mount systemd-tmpfiles-setup.service

RUN \
  # Installing Busser
  GEM_HOME="/tmp/verifier/gems" \
  GEM_PATH="/tmp/verifier/gems" \
  GEM_CACHE="/tmp/verifier/gems/cache" \
  gem install busser --no-rdoc --no-ri \
    --no-format-executable -n /tmp/verifier/bin --no-user-install && \

  # Busser plugins
  GEM_HOME="/tmp/verifier/gems" \
  GEM_PATH="/tmp/verifier/gems" \
  GEM_CACHE="/tmp/verifier/gems/cache" \
  gem install busser-serverspec serverspec --no-rdoc --no-ri

ENV LANG=en_US.UTF-8
VOLUME ["/sys/fs/cgroup", "/run"]
CMD  ["/usr/lib/systemd/systemd"]
