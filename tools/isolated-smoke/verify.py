from pathlib import Path
import socket,subprocess as sp,os,datetime as dt,hashlib,shutil,time,configparser,re,secrets,json,urllib.request as ur
import tempfile,sys
if os.name!='nt' or not __debug__:raise SystemExit('Requires Windows and Python without -O')
HERE=Path(__file__).resolve().parent; R=HERE.parents[1]; B=Path(tempfile.mkdtemp(prefix='hospital-handover-')); print('Fixture:',B,flush=True);
T=Path(os.environ['CATALINA_HOME']); J=Path(os.environ['JAVA_HOME'])/'bin'; M=Path(os.environ['MYSQL_HOME'])/'bin'; C=B/'tomcat'; APP=C/'webapps/hospital'; A=APP/'WEB-INF/classes'; D=B/'mysql-data'; schema='booking_qa'; procs=[]
assert not C.exists() and not D.exists(); D.mkdir(); C.mkdir(); (C/'conf').mkdir(); (C/'logs').mkdir(); (C/'temp').mkdir(); (C/'work').mkdir()
logfile=B/'result.txt'; defenv=os.environ.copy()
for k in ('JAVA_TOOL_OPTIONS','_JAVA_OPTIONS','JDK_JAVA_OPTIONS','CLASSPATH','MYSQL_HOST','MYSQL_TCP_PORT','MYSQL_PWD','NODE_OPTIONS'):defenv.pop(k,None)
def emit(x):
 print(x,flush=True)
 with logfile.open('a',encoding='utf8') as f:f.write(str(x)+'\n')
def choose():
 with socket.socket() as s:s.bind(('127.0.0.1',0));return s.getsockname()[1]
port,web=choose(),choose();assert port!=web and min(port,web)>1024
rootpw,appw,login=(secrets.token_hex(20) for _ in range(3)); now=dt.date.today()+dt.timedelta(days=2); url=f'http://127.0.0.1:{web}/hospital'; init=B/'init.sql';basecmd=[M/'mysqld.exe','--no-defaults',f'--basedir={M.parent}',f'--datadir={D}']; flags=sp.CREATE_NO_WINDOW
def run(cmd,**kw):return sp.run(cmd,cwd=B,env=defenv,check=True,creationflags=flags,**kw)
def start(cmd,log,env):
 with (B/log).open('wb') as out:p=sp.Popen(cmd,cwd=B,env=env,stdout=out,stderr=sp.STDOUT,creationflags=flags)
 procs.append(p);return p
def sql(q,db=True):
 cmd=[M/'mysql.exe','--no-defaults','--protocol=TCP','--host=127.0.0.1',f'--port={port}','--connect-timeout=2','-uroot','--default-character-set=utf8mb4','-N','-B']+([schema] if db else [])
 r=sp.run(cmd,input=q if isinstance(q,bytes) else q.encode('utf8'),stdout=sp.PIPE,stderr=sp.PIPE,env={**defenv,'MYSQL_PWD':rootpw},creationflags=flags,timeout=12);assert r.returncode==0,('mysql client',r.returncode,re.findall(rb'ERROR [0-9]+',r.stderr));return r.stdout.decode('utf8').strip()
def snapshot(label):
 v=[list(map(int,sql("SELECT COUNT(*),SUM(state='待接诊'),SUM(state='已接诊') FROM guahao").split())),[list(map(int,row.split())) for row in sql('SELECT total,remain FROM paiban ORDER BY id').splitlines()]];emit(f'{label}: [rows,pending,accepted], [[total,remaining] AM,PM] = {v}');return v
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def ui(stage,id=''):
 r=sp.run(['node',HERE/'ui.cjs',url,stage,str(now),str(id)],cwd=B,env={**defenv,'QA_LOGIN_PW':login},stdout=sp.PIPE,stderr=sp.STDOUT,timeout=110,creationflags=flags);emit(r.stdout.decode('utf8','replace').strip());assert r.returncode==0,'browser '+stage
try:
 with (B/'db-init.log').open('wb') as out:run(basecmd+['--initialize-insecure','--console'],stdout=out,stderr=sp.STDOUT)
 uid=configparser.ConfigParser();uid.read(D/'auto.cnf');uuid=uid['auto']['server-uuid'];init.write_text(f"ALTER USER 'root'@'localhost' IDENTIFIED BY '{rootpw}';\nCREATE DATABASE {schema} CHARACTER SET gbk;\nCREATE USER 'fixture_app'@'127.0.0.1' IDENTIFIED BY '{appw}';\nGRANT SELECT,INSERT,UPDATE ON {schema}.* TO 'fixture_app'@'127.0.0.1';\n",encoding='ascii')
 mysql=start(basecmd+['--console',f'--port={port}','--bind-address=127.0.0.1','--mysqlx=OFF','--skip-log-bin',f'--init-file={init}'],'mysql.log',defenv)
 # Wait for the private server's own startup message before opening any connection.
 for _ in range(120):
  if mysql.poll()!=None:raise RuntimeError('fixture mysqld stopped')
  if b'ready for connections' in (B/'mysql.log').read_bytes():break
  time.sleep(.25)
 else:raise RuntimeError('fixture mysqld not ready')
 assert sql('SELECT @@server_uuid')==uuid and Path(sql('SELECT @@datadir').replace('\\\\','\\')).resolve()==D.resolve() and int(sql('SELECT @@port'))==port
 init.unlink();emit(f'Fixture verified: private datadir, UUID, loopback port {port}, MySQL '+sql('SELECT VERSION()'))
 ddl=[];cur=[]
 with (R/'db/hospital_init.sql').open('rb') as f:
  for l in f:
   if not cur and not l.startswith(b'CREATE TABLE `'):continue
   cur.append(l)
   if l.rstrip().endswith(b';'):
    block=b''.join(cur);assert re.fullmatch(rb'CREATE TABLE `[a-z_]+`\s*\(.*\) ENGINE=InnoDB[^;]*;\s*',block,re.S) and b'INSERT INTO' not in block;ddl.append(block);cur=[]
 assert len(ddl)==16;sql(b'\n'.join(ddl));sql(f"INSERT INTO loginuser(loginname,loginpwd,usertype) VALUES ('QA-patient','{login}','病人'),('QA-doctor','{login}','医生'); INSERT INTO doctor(name,kebie) VALUES ('QA-doctor','QA-dept'); INSERT INTO paiban(id,doctor_name,kebie,work_date,shift,total,remain) VALUES (1,'QA-doctor','QA-dept','{now}','上午',6,4),(2,'QA-doctor','QA-dept','{now}','下午',4,3); INSERT INTO guahao(id,number,name,kebie,doctor,riqi,state,beizhu) VALUES (1,'QA-legacy-1','QA-patient','QA-dept','QA-doctor','{now}','待接诊','QA-legacy-1'),(2,'QA-legacy-2','QA-patient','QA-dept','QA-doctor','{now}','已接诊','QA-legacy-2');")
 sql(f"INSERT INTO loginuser(loginname,loginpwd,usertype) VALUES ('QA-admin','{login}','管理员'); INSERT INTO cost(name,state,jine) VALUES ('QA-legacy','草稿','1.00');")
 # Stable snapshot from identical legacy columns, all slots and all table counts.
 cols=sql('SHOW COLUMNS FROM guahao').splitlines();fields=','.join('`'+x.split('\t')[0]+'`' for x in cols);tables=sql('SHOW TABLES').splitlines()
 def data():return (sql('SELECT '+fields+' FROM guahao ORDER BY id'),sql('SELECT * FROM paiban ORDER BY id'),[sql('SELECT COUNT(*) FROM `'+t+'`') for t in tables])
 original=data();pre=snapshot('Before migration'); m=R/'db/migrations/2026-11-25-booking-shift.sql';sql(m.read_bytes());assert data()==original and snapshot('After migration')==pre;assert sql('SELECT COUNT(*) FROM guahao WHERE booking_shift IS NULL AND booking_request_id IS NULL')=='2';assert sql("SELECT GROUP_CONCAT(column_name ORDER BY seq_in_index) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='guahao' AND index_name='uk_guahao_patient_request' AND non_unique=0")=='name,booking_request_id';emit('PASS migration, all 16 table counts, legacy columns, 2 NULL pairs, unique index, schedule rows identical')
 sql((R/'db/migrations/2026-11-26-prescription-cost.sql').read_bytes());assert data()==original; assert sql("SELECT COUNT(*) FROM cost WHERE rx_item_id IS NULL AND jine='1.00'")=='1';assert sql("SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cost' AND COLUMN_NAME='rx_item_id' AND REFERENCED_TABLE_NAME='cf_item' AND REFERENCED_COLUMN_NAME='id'")=='1';assert sql("SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='cost' AND column_name='rx_item_id' AND non_unique=0")=='1';emit('PASS second migration: old cost intact, nullable link, unique index, FK; all row counts stable')
 sql((R/'db/migrations/2026-11-26-visit-notes.sql').read_bytes());assert data()==original and sql('SELECT COUNT(*) FROM guahao WHERE patient_account_id IS NOT NULL')=='0';emit('PASS visit migration leaves legacy identity unbound')
 # Extract complete webroot except private LLM settings and stale output. Keep project bytes for every copied asset.
 files=[R/p for p in sp.check_output(['git','ls-files','-z','--','WebRoot'],cwd=R).decode('utf8').split('\0') if p and Path(p).name!='llm.properties' and Path(p).suffix.lower()!='.class'];
 for p in files:
  target=APP/p.relative_to(R/'WebRoot');target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,target)
 A.mkdir(parents=True,exist_ok=True);assert all(sha(p)==sha(APP/p.relative_to(R/'WebRoot')) for p in files)
 src=sorted((R/'src').rglob('*.java'));cp=os.pathsep.join(map(str,[T/'lib/*',APP/'WEB-INF/lib/*']));run([J/'javac.exe','-proc:none','-encoding','UTF-8','-cp',cp,'-d',A,*src]);emit(f'Build: {len(src)} Java sources, {len(list(A.rglob("*.class")))} fresh classes; {len(files)} matching web files including {len(list(APP.rglob("*.jsp")))} JSPs')
 helper=B/'adapter';helper.mkdir();run([J/'javac.exe','-d',helper,HERE/'OnlyFixture.java']);mf=B/'MANIFEST.MF';mf.write_text('Manifest-Version: 1.0\nPremain-Class: OnlyFixture\n\n',encoding='ascii');jar=B/'fixture.jar';run([J/'jar.exe','cfm',jar,mf,'-C',helper,'.']);
 for x in ('web.xml','catalina.properties','jaspic-providers.xml','logging.properties'):shutil.copyfile(T/'conf'/x,C/'conf'/x)
 (C/'conf/context.xml').write_text('<Context><Manager pathname=""/></Context>',encoding='ascii');(C/'conf/server.xml').write_text(f'<Server port="-1"><Service name="Catalina"><Connector address="127.0.0.1" port="{web}" protocol="HTTP/1.1" URIEncoding="UTF-8"/><Engine name="Catalina" defaultHost="localhost"><Host name="localhost" appBase="webapps" autoDeploy="false" deployOnStartup="true"/></Engine></Service></Server>',encoding='ascii')
 tenv={**defenv,'FIXTURE_PORT':str(port),'FIXTURE_PW':appw,'FIXTURE_UUID':uuid};tlog=B/'tomcat.log';tom=start([J/'java.exe',f'-javaagent:{jar}','-verbose:class','-Dfile.encoding=UTF-8','-Djava.awt.headless=true',f'-Dcatalina.base={C}',f'-Dcatalina.home={T}',f'-Djava.io.tmpdir={C}/temp','-cp',os.pathsep.join(map(str,[T/'bin/bootstrap.jar',T/'bin/tomcat-juli.jar'])),'org.apache.catalina.startup.Bootstrap','start'],'tomcat.log',tenv)
 for _ in range(16):
  if tom.poll()!=None:raise RuntimeError('fixture Tomcat exited')
  if b'Server startup in' in tlog.read_bytes() or b'org.apache.coyote.AbstractProtocol.start' in tlog.read_bytes():break
  time.sleep(.25)
 opener=ur.build_opener(ur.ProxyHandler({}));r=opener.open(url+'/login.jsp',timeout=20);assert r.status==200;emit(f'Deployed full app at loopback port {web}; original login HTTP 200')
 ui('patient');expected=[ [3,2,1],[[6,3],[4,3]] ];assert snapshot('After booking')==expected;row=sql("SELECT id,booking_shift,riqi,state,LENGTH(booking_request_id) FROM guahao WHERE beizhu='QA-new'").split('\t');assert row[1:]==['上午',str(now),'待接诊','32'];rid=int(row[0]);assert sql('SELECT '+fields+' FROM guahao WHERE id IN (1,2) ORDER BY id')==original[0];emit('New synthetic appointment ID '+str(rid)+' / '+str(now));
 lines=tlog.read_text(encoding='utf8',errors='replace').splitlines();orig=[l for l in lines if l.startswith('CLASS ORIGIN com/hospital/AppointmentBooking ')];assert len(orig)==1 and '/webapps/hospital/WEB-INF/classes/' in orig[0].replace('\\','/') and 'WebappClassLoader' in orig[0] and B.name in orig[0];assert any('FIXTURE ONLY: confirmed booking_qa and expected server UUID' in l for l in lines);emit(orig[0]);assert any('Loaded com.hospital.AppointmentBooking ' in l for l in lines);emit('PASS JVM reported class loaded');ui('control',rid);assert snapshot('After denied POST')==expected
 ui('doctor',rid);assert snapshot('After intake')==[[3,1,2],[[6,3],[4,3]]] and sql(f'SELECT state FROM guahao WHERE id={rid}')=='已接诊' and sql('SELECT '+fields+' FROM guahao WHERE id IN (1,2) ORDER BY id')==original[0];emit('PASS only the new appointment changed state; old records and both slots reconciled')
 sql("INSERT INTO guahao(id,name,doctor,kebie,state) VALUES(900001,'QA-patient','QA-doctor','QA-dept','已接诊'),(900002,'QA-patient','QA-other','QA-dept','已接诊'),(900003,'QA-unknown','QA-doctor','QA-dept','已接诊'),(900004,'QA-duplicate','QA-doctor','QA-dept','已接诊'); INSERT INTO loginuser(loginname,usertype) VALUES ('QA-duplicate','病人'),('QA-duplicate','病人'); INSERT INTO cost_dict(code,name,price,active) VALUES('QA-F','QA-fee',1,1);")
 sql("UPDATE guahao SET patient_account_id=(SELECT id FROM loginuser WHERE loginname='QA-patient') WHERE id IN (1,900001,900002); UPDATE guahao SET patient_account_id=(SELECT MIN(id) FROM loginuser WHERE loginname='QA-duplicate') WHERE id=900004;")
 ui('notes',rid);assert sql(f"SELECT COUNT(*) FROM bingli WHERE visit_id={rid} AND patientname='QA-patient' AND doctor='QA-doctor' AND zhenduan='QA-reviewed'")=='1' and sql('SELECT COUNT(*) FROM bingli')=='1' and sql("SELECT COUNT(*) FROM cost WHERE xiangmu='QA-fee' AND name='QA-patient'")=='1' and sql('SELECT COUNT(*) FROM cost')=='2';emit('PASS exactly one note and fee, no denied writes or same-name mixup')
 ui('patientNote');ui('admin');assert not (APP/'WEB-INF/llm.properties').exists();emit('PASS no real model settings deployed; JVM outbound restricted to fixture database');
finally:
 for p in reversed(procs):
  if p.poll() is None:
   if p is mysql:
    z=sp.run([M/'mysqladmin.exe','--no-defaults','--protocol=TCP','--host=127.0.0.1',f'--port={port}','--user=root','shutdown'],env={**defenv,'MYSQL_PWD':rootpw},stdout=sp.DEVNULL,stderr=sp.DEVNULL,timeout=20);assert z.returncode==0
   else:p.terminate()
   p.wait(timeout=20)
 if init.exists():init.unlink()
 emit('Stopped owned processes: '+','.join(str(p.pid) for p in procs if p.poll() is not None))
