<p>Jolokia - приложение, выполняющего роль агента и/или прокси для мониторинга локальной или удаленной Java-машины по JMX. Более подробно об этом приложении можно прочитать на <a href="http://www.jolokia.org.">официальном сайте</a>.
</p>

<b>Установка.</b>

Репозиторий, содержащий исходники RPM-пакета для RHEL/CentOS 6: https://github.com/sklochkov/jolokia

Необходимые зависимости из EPEL:

tomcat

tomcat-lib

tomcat-servlet

tomcat-el-2.2-api

tomcat-jsp-2.2-api
Использование jolokia в режиме прокси

На целевых серверах должен быть включен JMX без SSL, например:
-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=8161 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false

Запросы подаются POST'ом на http://jolokia-server:8080/jolokia/. Пример запроса:
{
    "type" : "read",
    "mbean" : "java.lang:type=Memory",
    "attribute" : "HeapMemoryUsage",
    "target" : {
        "url" : "service:jmx:rmi:///jndi/rmi://mdir-k01:8161/jmxrmi",
        "user": "guest",
        "password": ""
    }
}
curl -d@post.json 'http://localhost:8080/jolokia/'
{"timestamp":1401097244,"status":200,"request":{"mbean":"java.lang:type=Memory","target":{"env":{"password":"","user":"guest"},"url":"service:jmx:rmi:\/\/\/jndi\/rmi:\/\/mdir-k01:8161\/jmxrmi"},"attribute":"HeapMemoryUsage","type":"read"},"value":{"max":17129537536,"committed":17129537536,"init":17179869184,"used":273725128}}
Полезные атрибуты
Имя
    
Параметры
java.lang:type=ClassLoading LoadedClassCount
java.lang:type=GarbageCollector,name=ConcurrentMarkSweep    

CollectionTime

CollectionCount
java.lang:type=GarbageCollector,name=ParNew 

CollectionTime

CollectionCount
java.lang:type=Memory   

HeapMemoryUsage.commited

HeapMemoryUsage.used

NonHeapMemoryUsage.commited

NonHeapMemoryUsage.used
java.lang:type=Threading    ThreadCount
