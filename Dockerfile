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

#FROM scratch as squash
#COPY --from=bootstrap / /
#RUN chown -R tor:tor /var/lib/tor
#SHELL ["/usr/bin/bash", "-l", "-c"]
#ARG TEST
#
#FROM squash as test
#ARG TEST
#RUN tor --verify-config \
# && sleep 127           \
# && xbps-install -S     \
# && exec true || exec false
#
#FROM squash as final
#
#ARG TEST
#ENTRYPOINT ["/usr/local/bin/cpuminer"]
#

#
#FROM innovanon/pgo-cpuminer-onion as bootstrap
#
FROM bootstrap as profiler
SHELL ["/bin/sh", "-c"]
RUN ln -sfv cpuminer /usr/local/bin/support
SHELL ["/usr/bin/bash", "-l", "-c"]
ARG TEST
ENV TEST=$TEST
# TODO loooooooooong time
RUN sleep 91

FROM innovanon/void-base as builder
COPY --from=profiler /var/cpuminer /var/cpuminer

ARG CPPFLAGS
ARG   CFLAGS
ARG CXXFLAGS
ARG  LDFLAGS

ENV CHOST=x86_64-linux-gnu
ENV CC=$CHOST-gcc
ENV CXX=$CHOST-g++
ENV FC=$CHOST-gfortran
ENV NM=$CC-nm
ENV AR=$CC-ar
ENV RANLIB=$CC-ranlib
ENV STRIP=$CHOST-strip

ENV CPPFLAGS="$CPPFLAGS"
ENV   CFLAGS="$CFLAGS"
ENV CXXFLAGS="$CXXFLAGS"
ENV  LDFLAGS="$LDFLAGS"

ENV PREFIX=/opt/cpuminer
ENV CPPFLAGS="-I$PREFIX/include $CPPFLAGS"
ENV CPATH="$PREFIX/incude:$CPATH"
ENV    C_INCLUDE_PATH="$PREFIX/include:$C_INCLUDE_PATH"
ENV OBJC_INCLUDE_PATH="$PREFIX/include:$OBJC_INCLUDE_PATH"

ENV LDFLAGS="-L$PREFIX/lib $LDFLAGS"
ENV    LIBRARY_PATH="$PREFIX/lib:$LIBRARY_PATH"
ENV LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
ENV     LD_RUN_PATH="$PREFIX/lib:$LD_RUN_PATH"

ENV PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PKG_CONFIG_LIBDIR"
ENV PKG_CONFIG_PATH="$PREFIX/share/pkgconfig:$PKG_CONFIG_LIBDIR:$PKG_CONFIG_PATH"

ARG ARCH=generic
ENV ARCH="$ARCH"

ENV CPPFLAGS="-DUSE_ASM $CPPFLAGS"
ENV   CFLAGS="-march=$ARCH -mtune=$ARCH $CFLAGS"

# PGO
ENV   CFLAGS="-fipa-profile -fprofile-reorder-functions -fvpt -fprofile-arcs -fprofile-use -fprofile-dir=/var/cpuminer -fprofile-correction  $CFLAGS"
ENV  LDFLAGS="-fipa-profile -fprofile-reorder-functions -fvpt -fprofile-arcs -fprofile-use -fprofile-dir=/var/cpuminer -fprofile-correction $LDFLAGS"

# Debug
ENV CPPFLAGS="-DNDEBUG $CPPFLAGS"
ENV   CFLAGS="-Ofast -g0 $CFLAGS"

# Static
ENV  LDFLAGS="-static -static-libgcc -static-libstdc++ $LDFLAGS"

# LTO
ENV   CFLAGS="-fuse-linker-plugin -flto $CFLAGS"
ENV  LDFLAGS="-fuse-linker-plugin -flto $LDFLAGS"

# Dead Code Strip
ENV   CFLAGS="-ffunction-sections -fdata-sections $CFLAGS"
ENV  LDFLAGS="-Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections $LDFLAGS"

# Optimize
ENV   CLANGFLAGS="-ffast-math -fassociative-math -freciprocal-math -fmerge-all-constants $CFLAGS"
ENV       CFLAGS="-fipa-pta -floop-nest-optimize -fgraphite-identity -floop-parallelize-all $CLANGFLAGS"

ENV CLANGXXFLAGS="$CLANGFLAGS $CXXFLAGS"
ENV CXXFLAGS="$CFLAGS $CXXFLAGS"

WORKDIR /tmp
RUN sleep 91                                 \
 && cd                          zlib         \
 && ./configure --prefix=$PREFIX             \
      --const --static --64                  \
 && make -j$(nproc)                          \
 && make install                             \
 && cd ..                                    \
 && rm -rf                      zlib         \
 && cd                           jansson     \
 && autoreconf -fi                           \
 && ./configure --prefix=$PREFIX             \
        --target=$CHOST           \
        --host=$CHOST             \
	--disable-shared                     \
	--enable-static                      \
	CPPFLAGS="$CPPFLAGS"                 \
	CXXFLAGS="$CXXFLAGS"                 \
	CFLAGS="$CFLAGS"                     \
	LDFLAGS="$LDFLAGS"                   \
        CPATH="$CPATH"                                \
        C_INCLUDE_PATH="$C_INCLUDE_PATH"              \
        OBJC_INCLUDE_PATH="$OBJC_INCLUDE_PATH"        \
        LIBRARY_PATH="$LIBRARY_PATH"                  \
        LD_LIBRARY_PATH="$LD_LIBRARY_PATH"            \
        LD_RUN_PATH="$LD_RUN_PATH"                    \
        PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR"        \
        PKG_CONFIG_PATH="$PKG_CONFIG_PATH"            \
	CC="$CC"                             \
	CXX="$CXX"                           \
        FC="$FC"                             \
        NM="$NM"                             \
        AR="$AR"                             \
        RANLIB="$RANLIB"                     \
        STRIP="$STRIP"                       \
 && make -j$(nproc)                          \
 && make install                             \
 && cd ..                                    \
 && rm -rf                       jansson
ENV CC=
ENV CXX=
ENV FC=
ENV NM=
ENV AR=
ENV RANLIB=
ENV STRIP=
RUN cd                           openssl              \
 && ./Configure --prefix=$PREFIX                      \
        --cross-compile-prefix=$CHOST-                \
	no-rmd160 no-sctp no-dso no-ssl2              \
	no-ssl3 no-comp no-idea no-dtls               \
	no-dtls1 no-err no-psk no-srp                 \
	no-ec2m no-weak-ssl-ciphers                   \
	no-afalgeng no-autoalginit                    \
	no-engine no-ec no-ecdsa no-ecdh              \
	no-deprecated no-capieng no-des               \
	no-bf no-dsa no-camellia no-cast              \
	no-gost no-md2 no-md4 no-rc2                  \
	no-rc4 no-rc5 no-whirlpool                    \
	no-autoerrinit no-blake2 no-chacha            \
	no-cmac no-cms no-crypto-mdebug               \
	no-ct no-crypto-mdebug-backtrace              \
	no-dgram no-dtls1-method                      \
	no-dynamic-engine no-egd                      \
	no-heartbeats no-hw no-hw-padlock             \
	no-mdc2 no-multiblock                         \
	no-nextprotoneg no-ocb no-ocsp                \
	no-poly1305 no-rdrand no-rfc3779              \
	no-scrypt no-seed no-srp no-srtp              \
	no-ssl3-method no-ssl-trace no-tls            \
	no-tls1 no-tls1-method no-ts no-ui            \
	no-unit-test no-whirlpool                     \
	no-posix-io no-async no-deprecated            \
	no-stdio no-egd                               \
        threads no-shared zlib                        \
	-static                                       \
        -DOPENSSL_SMALL_FOOTPRINT                     \
        -DOPENSSL_USE_IPV6=0                          \
        linux-x86_64                                  \
 && make -j$(nproc)                                   \
 && make install                                      \
 && cd ..                                             \
 && rm -rf                       openssl
ENV CC=$CHOST-gcc
ENV CXX=$CHOST-g++
ENV FC=$CHOST-gfortran
ENV NM=$CC-nm
ENV AR=$CC-ar
ENV RANLIB=$CC-ranlib
ENV STRIP=$CHOST-strip
RUN cd                        curl                    \
 && autoreconf -fi                                    \
 && ./configure --prefix=$PREFIX                      \
        --target=$CHOST           \
        --host=$CHOST             \
	--with-zlib="$PREFIX"                         \
	--with-ssl="$PREFIX"                          \
        --disable-shared                              \
	--enable-static                               \
	--enable-optimize                             \
	--disable-curldebug                           \
	--disable-ares                                \
	--disable-rt                                  \
	--disable-ech                                 \
	--disable-largefile                           \
	--enable-http                                 \
	--disable-ftp                                 \
	--disable-file                                \
	--disable-ldap                                \
	--disable-ldaps                               \
	--disable-rtsp                                \
	--enable-proxy                                \
	--disable-dict                                \
	--disable-telnet                              \
	--disable-tftp                                \
	--disable-pop3                                \
	--disable-imap                                \
	--disable-smb                                 \
	--disable-smtp                                \
	--disable-gopher                              \
	--disable-mqtt                                \
	--disable-manual                              \
	--disable-libcurl-option                      \
	--disable-ipv6                                \
	--disable-sspi                                \
	--disable-crypto-auth                         \
	--disable-ntlm-wb                             \
	--disable-tls-srp                             \
	--disable-unix-sockets                        \
	--disable-cookies                             \
	--disable-socketpair                          \
	--disable-http-auth                           \
	--disable-doh                                 \
	--disable-mine                                \
	--disable-dataparse                           \
	--disable-netrc                               \
	--disable-progress-meter                      \
	--disable-alt-svc                             \
	--disable-hsts                                \
	--without-brotli                              \
	--without-zstd                                \
	--without-winssl                              \
	--without-schannel                            \
	--without-darwinssl                           \
	--without-secure-transport                    \
	--without-amissl                              \
	--without-gnutls                              \
	--without-mbedtls                             \
	--without-wolfssl                             \
	--without-mesalink                            \
	--without-bearssl                             \
	--without-nss                                 \
	--without-libpsl                              \
	--without-libmetalink                         \
	--without-librtmp                             \
	--without-winidn                              \
	--without-libidn2                             \
	--without-nghttp2                             \
	--without-ngtcp2                              \
	--without-nghttp3                             \
	--without-quiche                              \
	--disable-threaded-resolver                   \
	CPPFLAGS="$CPPFLAGS"                          \
	CXXFLAGS="$CXXFLAGS"                          \
	CFLAGS="$CFLAGS"                              \
	LDFLAGS="$LDFLAGS"                            \
        CPATH="$CPATH"                                \
        C_INCLUDE_PATH="$C_INCLUDE_PATH"              \
        OBJC_INCLUDE_PATH="$OBJC_INCLUDE_PATH"        \
        LIBRARY_PATH="$LIBRARY_PATH"                  \
        LD_LIBRARY_PATH="$LD_LIBRARY_PATH"            \
        LD_RUN_PATH="$LD_RUN_PATH"                    \
        PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR"        \
        PKG_CONFIG_PATH="$PKG_CONFIG_PATH"            \
        CC="$CC"                                      \
        CXX="$CXX"                                    \
        FC="$FC"                                      \
        NM="$NM"                                      \
        AR="$AR"                                      \
        RANLIB="$RANLIB"                              \
        STRIP="$STRIP"                                \
 && make -j$(nproc)                                   \
 && make install                                      \
 && cd ..                                             \
 && rm -rf                    curl                    \
 && rm -v $PREFIX/bin/*curl*                          \
 && cd                                 cpuminer-yescrypt     \
 && ./autogen.sh                                             \
 && ./configure --prefix=$PREFIX                             \
        --target=$CHOST           \
        --host=$CHOST             \
	--disable-shared                                     \
	--enable-static                                      \
	--enable-assembly                                    \
        --with-curl=$PREFIX                                  \
        --with-crypto=$PREFIX                                \
	CPPFLAGS="$CPPFLAGS -DCURL_STATICLIB"                \
	CXXFLAGS="$CXXFLAGS"                                 \
	CFLAGS="$CFLAGS"                                     \
	LDFLAGS="$LDFLAGS"                                   \
        CPATH="$CPATH"                                \
        C_INCLUDE_PATH="$C_INCLUDE_PATH"              \
        OBJC_INCLUDE_PATH="$OBJC_INCLUDE_PATH"        \
        LIBRARY_PATH="$LIBRARY_PATH"                  \
        LD_LIBRARY_PATH="$LD_LIBRARY_PATH"            \
        LD_RUN_PATH="$LD_RUN_PATH"                    \
        PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR"        \
        PKG_CONFIG_PATH="$PKG_CONFIG_PATH"            \
        CC="$CC"                                             \
        CXX="$CXX"                                           \
        FC="$FC"                                             \
        NM="$NM"                                             \
        AR="$AR"                                             \
        RANLIB="$RANLIB"                                     \
        STRIP="$STRIP"                                       \
        LIBS='-lz -lcrypto -lssl -lcurl -ljansson'           \
 && cp -v cpu-miner.c.onion cpu-miner.c                             \
 && make -j$(nproc)                                                   \
 && make install                                                      \
 && cd ..                                                             \
 && rm -rf                             cpuminer-yescrypt              \
 && cd "$PREFIX"                                                      \
 && rm -rf etc include lib lib64 man share ssl                        \
 && cd bin                                                            \
 && find . -type f -exec "$STRIP" --strip-all          {} \;          \
 && find . -type f -exec upx --best --overlay=strip    {} \;

FROM scratch as squash
COPY --from=builder /usr/local/bin/cpuminer /cpuminer
ARG TEST
ENTRYPOINT ["/cpuminer"]

#FROM squash as test
#ARG TEST
# TODO
#RUN
#
#FROM squash as final
#

