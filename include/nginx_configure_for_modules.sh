#!/bin/bash
DEP_PKGS=(
	'libtexluajit2'
	'luajit'
	'libluajit-5.1-dev'
	'libluajit-5.1-common'
	'libluajit-5.1-2'
)
DEB_CODENAME="$(apt-cache policy | grep -E -o 'n=[a-z]+' | head -n1 | cut -d '=' -f2)"
APT_LIST="/etc/apt/sources.list.d/nginx_org_packages_ubuntu.list"
DEB_REPO="deb http://nginx.org/packages/ubuntu/ ${DEB_CODENAME} nginx"
DEB_SRC_REPO="deb-src http://nginx.org/packages/ubuntu/ ${DEB_CODENAME} nginx"
NGINX_BUILDROOT="/opt/rebuildnginx"
NGINX_MODULE_REPOS=(
	'https://github.com/vozlt/nginx-module-stream-sts.git'
	'https://github.com/vozlt/nginx-module-vts.git'
	'https://github.com/vozlt/nginx-module-sts.git'
	'https://github.com/ukarim/ngx_markdown_filter_module.git'
	'https://github.com/aperezdc/ngx-fancyindex.git'
	'https://github.com/sto/ngx_http_auth_pam_module.git'
	'https://github.com/yzprofile/ngx_http_dyups_module.git'
	'https://github.com/openresty/lua-nginx-module.git'
	'https://github.com/gnosek/nginx-upstream-fair.git'
	'https://github.com/openresty/headers-more-nginx-module.git'
	'https://github.com/Lax/traffic-accounting-nginx-module.git'
	'https://github.com/ajax16384/ngx_http_untar_module.git'
	'https://github.com/youzee/nginx-unzip-module.git'
	'https://github.com/yaoweibin/nginx_upstream_check_module.git'
	'https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng.git'
	'https://github.com/kvspb/nginx-auth-ldap.git'
	'https://github.com/leev/ngx_http_geoip2_module.git'
)

print_os_environment() {
	echo -e "\nUbuntu Version: $(grep -E "^VERSION=.*$" /etc/os-release | cut -d '=' -f2)\n"
	echo -e "\nOS Codename: ${DEB_CODENAME}\n"
	echo -e "\ndeb repo: ${DEB_REPO}\n"
	echo -e "\ndeb-src repo: ${DEB_SRC_REPO}\n"
	echo -e "\nNginx Build Root Directory: ${NGINX_BUILDROOT}\n"
}

is_directory() {
	if [[ ! -d $1 ]]; then
		echo -e "\nCreating ${1}" && mkdir -p "${1}" || echo -e "\n${1} Exists\n"
	fi
}

apt_setup() {
	(grep -E "^${1}$" "${2}") || (echo -e "\nAdding ${1} to ${2}\n" | cat "$1" >>"$2") && apt-get update
}

nginx_build_setup() {
	echo -e "\nInstalling NGINX Source\n" && cd "${NGINX_BUILDROOT}" && apt-get source nginx
	echo -e "\nInstalling NGINX Build Deps\n" && cd "${NGINX_BUILDROOT}" && apt-get build-dep nginx
}

git_repo_update() {
	for REPO in "${NGINX_MODULE_REPOS[@]}"; do
		REPODIR=$(echo "${REPO}" | tee >(sed -r 's/^.*\/(.*)\.git/\1/'))
		if [[ -d "${NGINX_BUILDROOT}/${REPODIR}" ]]; then
			echo -e "${REPO} found in ${NGINX_BUILDROOT}/${REPODIR}"
			cd "${NGINX_BUILDROOT}/${REPODIR}" || exit
			git checkout
			git pull
		else
			cd "${NGINX_BUILDROOT}" || exit
			git clone "${REPO}"
		fi
	done
}

print_os_environment

is_directory "${NGINX_BUILDROOT}"

cd "${NGINX_BUILDROOT}" && echo "${PWD}"

apt_setup "${DEB_REPO}" "${APT_LIST}"
apt_setup "${DEB_SRC_REPO}" "${APT_LIST}"
nginx_build_setup
git_repo_update

NGINX_VERSION=$(grep -E -o '^Version:\s[0-9|\\.]+' ./*.dsc | cut -d ' ' -f2)
NGINX_BUILDDIR="${NGINX_BUILDROOT}/nginx-${NGINX_VERSION}"
NGINX_USER='www-user'
NGINX_GROUP='www-group'
NGINX_CFLAGS="'-g -O2 -ffile-prefix-map=${NGINX_BUILDDIR}=. -flto=auto -ffat-lto-objects -flto=auto -ffat-lto-objects -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2'"
NGINX_LDFLAGS="'-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects -flto=auto -Wl,-z,relro -Wl,-z,now -fPIC'"

print_nginx_environment() {
	echo -e "\nNginx Build Version: ${NGINX_VERSION}\n"
	echo -e "\nNginx CFLAGS: ${NGINX_CFLAGS}\n"
	echo -e "\nNginx LDFLAGS: ${NGINX_LDFLAGS}\n"
	echo -e "\nNginx User: ${NGINX_USER}\n"
	echo -e "\nNginx Group: ${NGINX_GROUP}\n"
	echo -e "\nNginx Build Directory: ${NGINX_BUILDDIR}\n"
}

print_nginx_environment

is_directory "${NGINX_BUILDDIR}"

cd "${NGINX_BUILDDIR}" && echo "${PWD}"

./configure --with-cc-opt='${NGINX_CFLAGS}' --with-ld-opt='${NGINX_LDFLAGS}' --user="${NGINX_USER}" --group="${NGINX_GROUP}" \
	--prefix=/usr/share/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--http-log-path=/var/log/nginx/access.log \
	--error-log-path=/var/log/nginx/error.log \
	--lock-path=/var/lock/nginx.lock \
	--pid-path=/run/nginx.pid \
	--modules-path=/usr/lib/nginx/modules \
	--http-client-body-temp-path=/var/lib/nginx/body \
	--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
	--http-proxy-temp-path=/var/lib/nginx/proxy \
	--http-scgi-temp-path=/var/lib/nginx/scgi \
	--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
	--with-compat \
	--with-debug \
	--with-pcre-jit \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_realip_module \
	--with-http_auth_request_module \
	--with-http_v2_module \
	--with-http_dav_module \
	--with-http_slice_module \
	--with-threads \
	--with-http_addition_module \
	--with-http_flv_module \
	--with-http_geoip_module=dynamic \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_image_filter_module=dynamic \
	--with-http_mp4_module \
	--with-http_perl_module=dynamic \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_sub_module \
	--with-http_xslt_module=dynamic \
	--with-mail=dynamic \
	--with-mail_ssl_module \
	--with-stream \
	--with-stream_geoip_module=dynamic \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
	--add-dynamic-module="${NGINX_BUILDROOT}"/nginx-module-vts \
	--add-dynamic-module="${NGINX_BUILDROOT}"/ngx-fancyindex \
	--add-dynamic-module="${NGINX_BUILDROOT}"/ngx_markdown_filter_module \
	--add-dynamic-module="${NGINX_BUILDROOT}"/ngx_http_auth_pam_module \
	--add-dynamic-module="${NGINX_BUILDROOT}"/ngx_http_dyups_module \
	--add-dynamic-module="${NGINX_BUILDROOT}"/nginx_upstream_check_module \
	--add-dynamic-module="${NGINX_BUILDROOT}"/headers-more-nginx-module \
	--add-dynamic-module="${NGINX_BUILDROOT}"/nginx-auth-ldap \
	--add-dynamic-module="${NGINX_BUILDROOT}"/nginx-module-sts \
	--add-module="${NGINX_BUILDROOT}"/nginx-module-stream-sts

# --add-dynamic-module=./debian/modules/http-geoip2 \
# --add-dynamic-module=./debian/modules/http-headers-more-filter \
# --add-dynamic-module=./debian/modules/http-auth-pam \
# --add-dynamic-module=./debian/modules/http-cache-purge \
# --add-dynamic-module=./debian/modules/http-dav-ext \
# --add-dynamic-module=./debian/modules/http-ndk \
# --add-dynamic-module=./debian/modules/http-echo \
# --add-dynamic-module=./debian/modules/http-fancyindex \
# --add-dynamic-module=./debian/modules/nchan \
# --add-dynamic-module=./debian/modules/rtmp \
# --add-dynamic-module=./debian/modules/http-uploadprogress \
# --add-dynamic-module=./debian/modules/http-upstream-fair \
# --add-dynamic-module=./debian/modules/http-subs-filter \

echo -e "\nMaking Nginx target now\n"
make -j8 || echo -e "\nMake Failed\n"
