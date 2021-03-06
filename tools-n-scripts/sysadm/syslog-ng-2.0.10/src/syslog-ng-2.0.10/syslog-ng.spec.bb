#
#  Specfile used by BalaBit internally.
#
Summary: Next generation system logging daemon
Name: syslog-ng
Version: 2.0.10
Release: 1
License: GPL
Group: System Environment/Daemons
Source: syslog-ng_%{version}.tar.gz
URL: http://www.balabit.com
Packager: Tamas Pal <folti@balabit.com>
Vendor: Balabit IT Ltd.
BuildRoot: %{_tmppath}/%{name}-root
BuildRequires: bison, flex, gcc-c++, pkgconfig, glib2-devel, libevtlog-devel
Provides: syslog
#BuildConflicts:
#Exclusivearch: i386

%ifarch ppc
%define prefix /opt/freeware
%else
%define prefix /
%endif

%description
 Syslog-ng is a next generation system logger daemon which provides more
 capabilities and is has a more flexible configuration then the traditional
 syslog daemon.

%prep
%setup -q -n syslog-ng-%{version}


%build
./configure --prefix=%{prefix} --mandir=%{_mandir} --infodir=%{prefix}/share/info \
  --sysconfdir=/etc/syslog-ng --localstatedir=/var/lib/syslog-ng
make

%install
# pre install cleaning. for testing only.
[ $RPM_BUILD_ROOT = / ] || rm -rf $RPM_BUILD_ROOT
make install DESTDIR="$RPM_BUILD_ROOT"
# strip the binaries/ libraries
strip ${RPM_BUILD_ROOT}/%{prefix}/sbin/syslog-ng
./install-sh -d ${RPM_BUILD_ROOT}/etc/syslog-ng
./install-sh -d ${RPM_BUILD_ROOT}/etc/rc.d/init.d

if [ "%{_host_vendor}" = "redhat" ]; then
 ./install-sh -o root -g root -m 0755 contrib/rhel-packaging/syslog-ng.init \
   ${RPM_BUILD_ROOT}/etc/rc.d/init.d/syslog-ng
elif [ "%{_host_vendor}" = "suse" ]; then
 ./install-sh -o root -g root -m 0755 contrib/init.d.SuSE \
   ${RPM_BUILD_ROOT}/etc/rc.d/init.d/syslog-ng
fi

if [ "%{_host_vendor}" = "ibm" ];then
  ./install-sh -o root -g bin -m 0644 contrib/aix-packaging/syslog-ng.conf \
    ${RPM_BUILD_ROOT}/etc/syslog-ng/syslog-ng.conf
elif [ "%{_host_vendor}" = "redhat" ] || [ "%{_host_vendor}" = "suse" ]; then
  install -o root -g root -m 0644 contrib/rhel-packaging/syslog-ng.conf \
    ${RPM_BUILD_ROOT}/etc/syslog-ng/syslog-ng.conf
  install -D -o root -g root -m 0644 contrib/rhel-packaging/syslog-ng.logrotate \
    ${RPM_BUILD_ROOT}/etc/logrotate.d/syslog-ng
fi

# install documentation
[ -d "${RPM_BUILD_ROOT}/%{_prefix}/share/doc/syslog-ng-2.0.10" ] || ./install-sh -d "${RPM_BUILD_ROOT}/%{_prefix}/share/doc/syslog-ng-2.0.10"
./install-sh -o root -g root -m 0644 doc/reference/syslog-ng.html.tar.gz \
  ${RPM_BUILD_ROOT}/%{_prefix}/share/doc/syslog-ng-2.0.10/syslog-ng.html.tar.gz
./install-sh -o root -g root -m 0644 doc/reference/syslog-ng.txt \
  ${RPM_BUILD_ROOT}/%{_prefix}/share/doc/syslog-ng-2.0.10/syslog-ng.txt
./install-sh -o root -g root -m 0644 ChangeLog \
  ${RPM_BUILD_ROOT}/%{_prefix}/share/doc/syslog-ng-2.0.10/ChangeLog
./install-sh -o root -g root -m 0644 NEWS \
  ${RPM_BUILD_ROOT}/%{_prefix}/share/doc/syslog-ng-2.0.10/NEWS
./install-sh -o root -g root -m 0644 README \
  ${RPM_BUILD_ROOT}/%{_prefix}/share/doc/syslog-ng-2.0.10/README
./install-sh -o root -g root -m 0644 AUTHORS \
  ${RPM_BUILD_ROOT}/%{_prefix}/share/doc/syslog-ng-2.0.10/AUTHORS
./install-sh -o root -g root -m 0644 COPYING \
  ${RPM_BUILD_ROOT}/%{_prefix}/share/doc/syslog-ng-2.0.10/COPYING

%files
%defattr(-,root,root)
%{prefix}/sbin/syslog-ng
%{prefix}/bin/loggen
%{_mandir}/*
%docdir %{_prefix}/share/doc/syslog-ng-2.0.10
%{_prefix}/share/doc/syslog-ng-2.0.10/*
%config(noreplace) /etc/syslog-ng/syslog-ng.conf
%ifnos aix5.2
/etc/rc.d/init.d/syslog-ng
%config(noreplace) /etc/logrotate.d/syslog-ng
%endif

%post
%ifos aix5.2
echo "Checking whether the syslog-ng service is already registered... "
if ! /usr/bin/lssrc -s syslogng >/dev/null 2>&1; then
        echo "NO"
        echo "Registering syslog-ng service... "
        if /usr/bin/mkssys -s syslogng -p /opt/freeware/sbin/syslog-ng -u 0 \
          -a '-F -p /etc/syslog-ng.pid' -O -d -Q -S -n 15 -f 9 -E 20 -G ras -w 2 \
          >/dev/null 2>&1; then
                echo "SUCCESSFUL"
        else
                echo "FAILED"
        fi
else
        echo "YES"
fi

echo "Checking whether the syslogd service is registered..."
if /usr/bin/lssrc -s syslogd >/dev/null 2>&1; then
        echo "YES"
        if /usr/bin/lssrc -s syslogd|grep -E "^ syslogd.*active" > /dev/null 2>&1; then
                echo "Stopping the syslogd service..."
                if /usr/bin/stopsrc -s syslogd >/dev/null 2>&1; then
                        echo "SUCCESSFUL"
                else
                        echo "FAILED, continuing anyway"
                fi
        fi
        echo "Disabling syslogd service"
        if /usr/bin/rmssys -s syslogd >/dev/null 2>&1; then
                echo "SUCCESSFUL"
        else
                echo "FAILED"
        fi
else
        echo "NO"
fi

if /usr/bin/lssrc -s syslogng|grep -E "^ syslogng.*active" >/dev/null 2>&1; then
        echo "Stopping syslog-ng"
        /usr/bin/stopsrc -s syslogng
fi
echo "Starting syslog-ng"
/usr/bin/startsrc -s syslogng
#post end
%else
if [ "%{_host_vendor}" = "redhat" ]; then
  sh /etc/rc.d/init.d/syslog stop || true
elif [ "%{_host_vendor}" = "suse" ]; then
  sh /etc/init.d/syslog stop || true
  if [ -L /etc/init.d/syslog-ng ]; then
    rm -f /etc/init.d/syslog-ng
  fi
  ln -s /etc/rc.d/init.d/syslog-ng /etc/init.d/syslog-ng
fi
chkconfig --del syslog
chkconfig --add syslog-ng
sh /etc/rc.d/init.d/syslog-ng start || exit 0
%endif

%preun
%ifos aix5.2
	if /usr/bin/lssrc -s syslogng >/dev/null 2>&1; then
        	if /usr/bin/lssrc -s syslogng|grep -E "^ syslogng.*active" > /dev/null 2>&1; then
                	echo "Stopping syslog-ng"
	                /usr/bin/stopsrc -s syslogng
	        fi
        	echo "Unregistering syslog-ng"
	        if /usr/bin/rmssys -s syslogng >/dev/null 2>&1; then
        	        echo "SUCCESSFUL"
	        else
        	        echo "FAILED"
	        fi
	fi

# re-enable the standard syslogd subsystem
#subsysname:synonym:cmdargs:path:uid:auditid:standin:standout:standerr:action:multi:contact:svrkey:svrmtype:priority:sig norm:sigforce:display:waittime:grpname:
# syslogd:::/usr/sbin/syslogd:0:0:/dev/console:/dev/console:/dev/console:-O:-Q:-K:0:0:20:0:0:-d:20:ras:

	if ! /usr/bin/lssrc -s syslogd >/dev/null 2>&1; then
        	echo "Registering syslogd service"
	        if /usr/bin/mkssys -s syslogd -p /usr/sbin/syslogd -u 0 -O -Q -K -E 20 -d \
        	  -G ras >/dev/null 2>&1; then
	                echo "SUCCESSFUL"
        	else
                	echo "FAILED"
	        fi
	fi

	if /usr/bin/lssrc -s syslogd >/dev/null 2>&1; then
        	if ! /usr/bin/lssrc -s syslogd | grep -E "^ syslogd.*active" >/dev/null 2>&1; then
	                echo "Starting syslogd"
        	        /usr/bin/startsrc -s syslogd
	        fi
	fi
#preun end
%else
sh /etc/rc.d/init.d/syslog-ng stop || exit 0 
if [ "%{_host_vendor}" = "redhat" ]; then
  sh /etc/rc.d/init.d/syslog start || true
elif [ "%{_host_vendor}" = "suse" ]; then
  if [ -L /etc/init.d/syslog-ng ]; then
    rm -f /etc/init.d/syslog-ng
  fi
  sh /etc/init.d/syslog start || true
fi
%endif

%postun
%ifnos aix5.2
#chkconfig --force --del syslog-ng
#chkconfig --add syslog

%check
%endif

%clean
[ $RPM_BUILD_ROOT = / ] || rm -rf $RPM_BUILD_ROOT

%changelog
* Wed Nov 22 2006 Tamas Pal <folti@balabit.com>
- Added dependencies glib2-devel and pkgconfig.
- Configfiles /etc/syslog-ng/syslog-ng.conf and /etc/logrotate.d/syslog-ng no
  longer replaced blindly during upgrade.
* Fri Nov 3 2006 Tamas Pal <folti@balabit.com>
- Added SuSE packaging.
- Added AIX 5.2 packaging.
- Now provides syslog.
- Added dependency libevtlog-devel.
* Fri Jun 30 2006 Tamas Pal <folti@balabit.com>
- fixed typo in RHEL config file.
* Mon Mar 27 2006 Balazs Scheidler <bazsi@balabit.com>
- removed postscript version of the documentation
* Fri Sep 9 2005 Sandor Geller <wildy@balabit.com>
- fixed permissions of /etc/rc.d/init.d/syslog-ng
* Thu Jun 30 2005 Sandor Geller <wildy@balabit.com>
- packaging fixes, added logrotate script
* Thu Jun 23 2005 Sandor Geller <wildy@balabit.com>
- added upstream's documentation to the package
* Mon Jun 20 2005 Sandor Geller <wildy@balabit.com>
- initial RPM packaging for RHEL ES

# vim: ts=2 ft=spec
