FROM innovanon/pgo-cpuminer as bootstrap
RUN cd     cpuminer-yescrypt                                          \
 && cp -v cpu-miner.c.onion cpu-miner.c                             \
 && make -j$(nproc)                                                   \
 && make install                                                      \
 && git reset --hard                                                  \
 && git clean -fdx                                                    \
 && git clean -fdx                                                    \
 && cd ..                                                             \
 && cd $PREFIX                                                        \
 && rm -rf etc include lib lib64 man share ssl

FROM innovanon/voidlinux-pgo as final

FROM innovanon/voidlinux-pgo as final
COPY --from=bootstrap /opt/cpuminer/bin/cpuminer /usr/local/bin/
SHELL ["/bin/sh", "-c"]
RUN ln -sfv cpuminer /usr/local/bin/support
SHELL ["/usr/bin/bash", "-l", "-c"]
ARG TEST
ENV TEST=$TEST
VOLUME /var/cpuminer
ENTRYPOINT ["/usr/bin/env", "sleep"]
CMD ["91"]

