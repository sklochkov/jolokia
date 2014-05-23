%define _builddir .
%define _sourcedir .
%define _specdir .
%define _rpmdir .

Name: jolokia
Version: 1.2.1
Release: 3%{dist}

Summary: JMX to JSON agent and proxy
License: MIT
Group: System Environment/Daemons
Distribution: Red Hat Enterprise Linux

BuildArch: noarch

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
Requires: tomcat
Requires: java-1.7.0-openjdk

%define _basedir /var/lib/jolokia
%define _user tomcat
%define _jrepath /usr/lib/jvm/jre-1.7.0/

%description
Jolokia is a JMX-HTTP bridge giving an alternative to JSR-160 connectors. It is an agent based approach with support for many platforms. In addition to basic JMX operations it enhances JMX remoting with unique features like bulk requests and fine grained security policies. 


%prep
sed < jolokia.cfg.tmpl 's#__BASEDIR__#%{_basedir}#' | sed 's#__USER__#%{_user}#' | sed 's#__JREHOME__#%{_jrepath}#' > jolokia.cfg

%build


%install
%{__rm} -rf %{buildroot}
install -m 755 -d %{buildroot}/etc/init.d/
install -m 755 -d %{buildroot}/etc/sysconfig

install -m 755 -d %{buildroot}/%{_basedir}/{conf,bin,logs,work,temp,webapps}
install -m755 -d %{buildroot}/%{_basedir}/webapps/jolokia
install -m755 -d %{buildroot}/%{_basedir}/webapps/jolokia/META-INF
install -m755 -d %{buildroot}/%{_basedir}/webapps/jolokia/META-INF/maven
install -m755 -d %{buildroot}/%{_basedir}/webapps/jolokia/META-INF/maven/org.jolokia
install -m755 -d %{buildroot}/%{_basedir}/webapps/jolokia/META-INF/maven/org.jolokia/jolokia-war
install -m755 -d %{buildroot}/%{_basedir}/webapps/jolokia/WEB-INF
install -m755 -d %{buildroot}/%{_basedir}/webapps/jolokia/WEB-INF/classes
install -m755 -d %{buildroot}/%{_basedir}/webapps/jolokia/WEB-INF/lib

install -m 644 ./conf/context.xml %{buildroot}/%{_basedir}/./conf/context.xml
install -m 644 ./conf/catalina.policy %{buildroot}/%{_basedir}/./conf/catalina.policy
install -m 644 ./conf/logging.properties %{buildroot}/%{_basedir}/./conf/logging.properties
install -m 644 ./conf/web.xml %{buildroot}/%{_basedir}/./conf/web.xml
install -m 644 ./conf/tomcat-users.xml %{buildroot}/%{_basedir}/./conf/tomcat-users.xml
install -m 644 ./conf/catalina.properties %{buildroot}/%{_basedir}/./conf/catalina.properties
install -m 644 ./conf/server.xml %{buildroot}/%{_basedir}/./conf/server.xml
install -m 644 ./bin/catalina.sh %{buildroot}/%{_basedir}/./bin/catalina.sh
install -m 644 ./webapps/jolokia/META-INF/MANIFEST.MF %{buildroot}/%{_basedir}/./webapps/jolokia/META-INF/MANIFEST.MF
install -m 644 ./webapps/jolokia/META-INF/maven/org.jolokia/jolokia-war/pom.properties %{buildroot}/%{_basedir}/./webapps/jolokia/META-INF/maven/org.jolokia/jolokia-war/pom.properties
install -m 644 ./webapps/jolokia/META-INF/maven/org.jolokia/jolokia-war/pom.xml %{buildroot}/%{_basedir}/./webapps/jolokia/META-INF/maven/org.jolokia/jolokia-war/pom.xml
install -m 644 ./webapps/jolokia/WEB-INF/web.xml %{buildroot}/%{_basedir}/./webapps/jolokia/WEB-INF/web.xml
install -m 644 ./webapps/jolokia/WEB-INF/lib/jolokia-jsr160-1.2.1.jar %{buildroot}/%{_basedir}/./webapps/jolokia/WEB-INF/lib/jolokia-jsr160-1.2.1.jar
install -m 644 ./webapps/jolokia/WEB-INF/lib/jolokia-core-1.2.1.jar %{buildroot}/%{_basedir}/./webapps/jolokia/WEB-INF/lib/jolokia-core-1.2.1.jar
install -m 644 ./webapps/jolokia/WEB-INF/lib/json-simple-1.1.jar %{buildroot}/%{_basedir}/./webapps/jolokia/WEB-INF/lib/json-simple-1.1.jar
install -m 644 ./jolokia.cfg %{buildroot}/etc/sysconfig/jolokia
install -m 755 ./jolokia.init.sh %{buildroot}/etc/init.d/jolokia
rm -f jolokia.cfg

%clean
rm -rf $RPM_BUILD_ROOT
rm -f jolokia.cfg

%post
if [ $1 -eq 1 -o $1 -eq 2 ] ; then
	chkconfig --add jolokia
fi

%preun
if [ $1 -eq 0 ] ; then
	chkconfig --del jolokia
fi

%files

%dir %attr(0755, root, root) %{_basedir}
%dir %attr(0755, %{_user}, root) %{_basedir}/conf
%dir %attr(0755, %{_user}, root) %{_basedir}/logs
%dir %attr(0755, %{_user}, root) %{_basedir}/work
%dir %attr(0755, %{_user}, root) %{_basedir}/temp

%attr(0644, root, root) %{_basedir}/conf/context.xml
%attr(0644, root, root) %{_basedir}/conf/catalina.policy
%attr(0644, root, root) %{_basedir}/conf/logging.properties
%attr(0644, root, root) %{_basedir}/conf/web.xml
%attr(0644, root, root) %{_basedir}/conf/tomcat-users.xml
%attr(0644, root, root) %{_basedir}/conf/catalina.properties
%attr(0644, root, root) %{_basedir}/conf/server.xml
%attr(0755, root, root) %{_basedir}/bin/catalina.sh
%attr(0644, root, root) %{_basedir}/webapps/jolokia/META-INF/MANIFEST.MF
%attr(0644, root, root) %{_basedir}/webapps/jolokia/META-INF/maven/org.jolokia/jolokia-war/pom.properties
%attr(0644, root, root) %{_basedir}/webapps/jolokia/META-INF/maven/org.jolokia/jolokia-war/pom.xml
%attr(0644, root, root) %{_basedir}/webapps/jolokia/WEB-INF/web.xml
%attr(0644, root, root) %{_basedir}/webapps/jolokia/WEB-INF/lib/jolokia-jsr160-1.2.1.jar
%attr(0644, root, root) %{_basedir}/webapps/jolokia/WEB-INF/lib/jolokia-core-1.2.1.jar
%attr(0644, root, root) %{_basedir}/webapps/jolokia/WEB-INF/lib/json-simple-1.1.jar

%attr(0755, root, root) /etc/init.d/jolokia
%attr(0755, root, root) /etc/sysconfig/jolokia
