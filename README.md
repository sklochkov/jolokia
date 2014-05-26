<p>Jolokia - приложение, выполняющего роль агента и/или прокси для мониторинга локальной или удаленной Java-машины по JMX. Более подробно об этом приложении можно прочитать на <a href="http://www.jolokia.org.">официальном сайте</a>.
</p>

<h3>Установка.</h3>
<p>
Репозиторий, содержащий исходники RPM-пакета для RHEL/CentOS 6: https://github.com/sklochkov/jolokia
</p>
<p>
Необходимые зависимости из EPEL:
<ul>
<li>tomcat</li>
<li>tomcat-lib</li>
<li>tomcat-servlet</li>
<li>tomcat-el-2.2-api</li>
<li>tomcat-jsp-2.2-api</li>
</ul>
</p>
<h3>Использование jolokia в режиме прокси</h3>
<p>
На целевых серверах должен быть включен JMX без SSL, например:
<pre>
-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=8161 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false
</pre>

Запросы подаются POST'ом на http://jolokia-server.example.com:8080/jolokia/. Пример запроса:
<pre>
{
    "type" : "read",
    "mbean" : "java.lang:type=Memory",
    "attribute" : "HeapMemoryUsage",
    "target" : {
        "url" : "service:jmx:rmi:///jndi/rmi://target-server.example.com:8161/jmxrmi",
        "user": "guest",
        "password": ""
    }
}
</pre>
<pre>
curl -d@post.json 'http://jolokia-server.example.com:8080/jolokia/'
{"timestamp":1401097244,"status":200,"request":{"mbean":"java.lang:type=Memory","target":{"env":{"password":"","user":"guest"},"url":"service:jmx:rmi:\/\/\/jndi\/rmi:\/\/target-server.example.com:8161\/jmxrmi"},"attribute":"HeapMemoryUsage","type":"read"},"value":{"max":17129537536,"committed":17129537536,"init":17179869184,"used":273725128}}
</pre>
</p>

<h3>Полезные атрибуты</h3>

<table width="100%" border="1">
<thead>
<tr>
<th width="60%">Имя</th>
    
<th width="40%">Параметры</th>
</tr>
</thead>
<tbody>
<tr>
<td>java.lang:type=ClassLoading</td><td>LoadedClassCount</td>
</tr>
<tr>
<td>java.lang:type=GarbageCollector,name=ConcurrentMarkSweep</td>
<td>CollectionTime<br />
CollectionCount</td>
</tr>
<tr>
<td>java.lang:type=GarbageCollector,name=ParNew</td>
<td>CollectionTime<br />
CollectionCount</td>
</tr>
<tr>
<td>java.lang:type=Memory</td>
<td>HeapMemoryUsage.commited<br />
HeapMemoryUsage.used<br />
NonHeapMemoryUsage.commited<br />
NonHeapMemoryUsage.used</td>
</tr>
<tr>
<td>java.lang:type=Threading</td><td>ThreadCount</td>
</tr>
</tbody>
</table>
