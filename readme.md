# Instalación de cluster hadoop

### descripcion de los ambientes

Se utilizaran 3 servidores con las siguientes caracteristicas, se agrega archivo vagrantfile para la creacion de maquinas virtuales con virtualbox


| hostname          | ram | cores | espacio | so        | ip            |
|-------------------|-----|-------|---------|-----------|---------------|
| hadoop-namenode   | 8   | 4     | 100     | debian 10 | 192.168.15.10 |
| hadoop-datanode-2 | 8   | 4     | 100     | debian 10 | 192.168.15.11 |
| hadoop-datanode-3 | 8   | 4     | 100     | debian 10 | 192.168.15.12 |


## prerequisitos
### Instalación de paquetes en todos los nodos
los siguientes pasos a continuación se deben ejecutar en los tres servidores:

```shell
# instalación de paquetes
$ sudo apt-get install vim openssh-server software-properties-common python-software-properties
```

```shell
# instalación de java
$ sudo apt-get install default-jre -y
$ sudo apt-get install default-jdk -y
```

### Usuario de sistema
todos los pasos se deben realizar con un único usuario con permisos de sudo, en este caso será hadoop

```shell
$ sudo adduser hadoop # seguir los pasos, escoger una contraseña y aceptar
```
agregar el usuario al grupo sudoers

```shell
$ echo 'hadoop  ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
```

desde este punto todos los comandos siguientes se deben ejecutar con el usuario hadoop

```shell
$ sudo su - hadoop
```
### configuración de ssh
El usuario hadoop debe tener acceso ssh a todas los servidores usados, ejecutar los siguientes comandos:

```shell
$ ssh-keygen # generar una llave sin contraseña
$ ssh-copy-id hadoop@192.168.15.10
$ ssh-copy-id hadoop@192.168.15.11
$ ssh-copy-id hadoop@192.168.15.12
```
### configuración del archivo /etc/hosts

editamos el archivo /etc/hosts y agregamos las siguientes configuraciones
```config
192.168.15.10 hadoop-namenode
192.168.15.11 hadoop-datanode-2
192.168.15.12 hadoop-datanode-3
```
si es que existiera, debemos eliminar la siguiente linea del archivo /etc/hosts
```config
127.0.1.1 <hostname>
```
### descarga del empaquetado
Se instalará la version 3.2.2 de hadoop, asi que se necesita descargar el comprimido en /opt/hadoop en todos los servidores
```shell
$  wget https://archive.apache.org/dist/hadoop/common/hadoop-3.2.2/hadoop-3.2.2.tar.gz
```
### directorios de empaquetado
se deben crear carpetas con la siguiente estructura
```tree
/opt
  /hadoop
    /logs
  /hdfs
    /datanode
    /namenode
  /yarn
    /logs
```
sudo chown -R hadoop:hadoop  /opt

se debe asignar los permisos de estas carpetas al usuario hadoop

```shell
$ tar -xvf hadoop-3.2.2.tar.gz \
  --directory=/opt/hadoop \
  --strip 1
```

### Archivos de configuración de Hadoop
(estos pasos deben ejecutarse en todos los servidores)

Editar el archivo /home/hadoop/.bashrc y agregar las siguientes lineas
```config
export HADOOP_HOME=/opt/hadoop
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export HDFS_NAMENODE_USER=hadoop
export HDFS_DATANODE_USER=hadoop
export HDFS_SECONDARYNAMENODE_USER=hadoop
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_MAPRED_HOME=/opt/hadoop
export HADOOP_COMMON_HOME=/opt/hadoop
export HADOOP_HDFS_HOME=/opt/hadoop
export YARN_HOME=/opt/hadoop
```
Editar el archivo /opt/hadoop/etc/hadoop/hadoop-env.sh agregando las siguientes variables
```config
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export HADOOP_LOG_DIR=/opt/hadoop/logs
```
recargar la nueva configuración:
```shell
$ source /home/hadoop/.bashrc
```

Para comprobar que haya salido bien ejecutar el comando, se debe esperar una respuesta positiva
```shell
$ hadoop
```
# Configuraciones en el nodo maestro
Inicialmente, actualizaremos el archivo hdfs-site.xml

```shell
$ vim /opt/hadoop/etc/hadoop/hdfs-site.xml
```
```xml
<?xml version="1.0"?>
<configuration>
        <property>
                <name>dfs.namenode.name.dir</name>
                <value>file:///opt/hdfs/namenode</value>
                <description>NameNode directory for namespace and transaction logs storage.</description>
        </property>
        <property>
                <name>dfs.datanode.data.dir</name>
                <value>file:///opt/hdfs/datanode</value>
                <description>DataNode directory</description>
        </property>
        <property>
                <name>dfs.replication</name>
                <value>3</value>
                </property>
        <property>
                <name>dfs.permissions</name>
                <value>false</value>
        </property>
        <property>
                <name>dfs.datanode.use.datanode.hostname</name>
                <value>false</value>
        </property>
        <property>
                <name>dfs.namenode.datanode.registration.ip-hostname-check</name>
                <value>false</value>
        </property>
</configuration>
```
Luego se debe editar el archivo core-site.xml
```shell
$ vim /opt/hadoop/etc/hadoop/core-site.xml
```
```xml
<?xml version="1.0"?>
<configuration>
        <property>
                <name>fs.defaultFS</name>
                <value>hdfs://hadoop-namenode:9820/</value>
                <description>NameNode URI</description>
        </property>
        <property>
                <name>io.file.buffer.size</name>
                <value>131072</value>
                <description>Buffer size</description>
        </property>
</configuration>
```
Luego editar el archivo /opt/hadoop/etc/hadoop/yarn-site.xml

```shell
$ vim /opt/hadoop/etc/hadoop/yarn-site.xml
```
```xml
<?xml version="1.0"?>
<configuration>
        <property>
                <name>yarn.nodemanager.aux-services</name>
                <value>mapreduce_shuffle</value>
                <description>Yarn Node Manager Aux Service</description>
        </property>
        <property>
                <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
                <value>org.apache.hadoop.mapred.ShuffleHandler</value>
        </property>
        <property>
                <name>yarn.nodemanager.local-dirs</name>
                <value>file:///opt/yarn/local</value>
        </property>
        <property>
                <name>yarn.nodemanager.log-dirs</name>
                <value>file:///opt/yarn/logs</value>
        </property>
</configuration>
```
```shell
$ vim /opt/hadoop/etc/hadoop/mapred-site.xml
```
```xml
<?xml version="1.0"?>
<configuration>
        <property>
                <name>mapreduce.framework.name</name>
                <value>yarn</value>
                <description>MapReduce framework name</description>
        </property>
        <property>
                <name>mapreduce.jobhistory.address</name>
                <value>hadoop-namenode:10020</value>
                <description>Default port is 10020.</description>
        </property>
        <property>
                <name>mapreduce.jobhistory.webapp.address</name>
                <value> hadoop-namenode:19888</value>
                <description>Default port is 19888.</description>
        </property>
        <property>
                <name>mapreduce.jobhistory.intermediate-done-dir</name>
                <value>/mr-history/tmp</value>
                <description>Directory where history files are written by MapReduce jobs.</description>
        </property>
        <property>
                <name>mapreduce.jobhistory.done-dir</name>
                <value>/mr-history/done</value>
                <description>Directory where history files are managed by the MR JobHistory Server.</description>
        </property>
</configuration>
```

Ahora debemos formatear el nodo maestro
```shell
$ hdfs namenode -format
```
Finalmente, tenemos que agregar las ips del cluster en el archivo workers
```shell
$ vim /opt/hadoop/etc/hadoop/workers
```
```config
192.168.15.10
192.168.15.11
192.168.15.12
```
## Configurando los nodos de datos
estas instrucciones se deben ejecutar en todos los nodos de datos (en test)
Tenemos que actualizar hdfs-site.xml, core-site.xml, yarn-site.xml y mapred-site.xml ubicados en el directorio / opt / hadoop / etc / hadoop de la siguiente manera:

```shell
$ vim  /opt/hadoop/etc/hadoop/hdfs-site.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
        <property>
                <name>dfs.datanode.data.dir</name>
                <value>file:///opt/hdfs/datanode</value>
                <description>DataNode directory</description>
        </property>
        <property>
                <name>dfs.replication</name>
                <value>3</value>
        </property>
        <property>
                <name>dfs.permissions</name>
                <value>false</value>
        </property>
        <property>
                <name>dfs.datanode.use.datanode.hostname</name>
                <value>false</value>
        </property>
</configuration>
```

```shell
$ vim  /opt/hadoop/etc/hadoop/core-site.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
        <property>
                <name>fs.defaultFS</name>
                <value>hdfs://hadoop-namenode:9820/</value>
                <description>NameNode URI</description>
        </property>
</configuration>
```

```shell
$ vim  /opt/hadoop/etc/hadoop/yarn-site.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
        <property>
                <name>yarn.nodemanager.aux-services</name>
                <value>mapreduce_shuffle</value>
                <description>Yarn Node Manager Aux Service</description>
        </property>
</configuration>
```

```shell
$ vim  /opt/hadoop/etc/hadoop/mapred-site.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
        <property>
                <name>mapreduce.framework.name</name>
                <value>yarn</value>
                <description>MapReduce framework name</description>
        </property>
</configuration>
```

# Iniciar hadoop
Ejecutar el siguiente comando desde el nodo namenode
```shell
$ start-all.sh
```
Se debe de ver el siguiente mensaje:
```shell
Starting namenodes on [hadoop-namenode]
Starting datanodes
Starting secondary namenodes [hadoop-namenode]
```

# Acceder a hadoop desde el navegador

Namenode
acceder a la siguiente URL: https://192.168.15.10:9870/
ResourceManager
acceder a la siguiente URL: https://192.168.15.10:8088/
