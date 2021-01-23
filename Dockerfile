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

FROM scratch as squash
COPY --from=builder / /
RUN chown -R tor:tor /var/lib/tor
SHELL ["/usr/bin/bash", "-l", "-c"]
ARG TEST

FROM squash as test
ARG TEST
RUN tor --verify-config \
 && sleep 127           \
 && xbps-install -S     \
 && exec true || exec false

FROM squash as final

ARG TEST
ENTRYPOINT ["/usr/local/bin/cpuminer"]

