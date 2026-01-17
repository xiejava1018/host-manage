## 🔒 深度安全检查

### 🎯 异常进程检测

**高CPU/内存占用进程**：
✅ **正常**：未发现异常高资源占用进程

**挖矿程序检测**：
✅ **正常**：未检测到挖矿进程

**可疑进程名检测**：
✅ **正常**：未发现可疑进程名

**可疑路径进程检测**：
✅ **正常**：未发现从可疑路径运行的进程

### 🌐 网络连接安全

**反向Shell检测**：
✅ **正常**：未检测到反向Shell连接

**监听端口检查**：
当前监听端口：22 53 5003 5443 8000 8080 8088 8181 8488 9001 33060 63790 
✅ **正常**：未检测到高危端口监听

**外部连接统计**：
外部连接数：3

### 📁 文件系统安全

**最近 24 小时修改的文件（重点目录）**：
✅ **正常**：未发现可疑的最近修改文件

**SUID/SGID 可执行文件**：
发现以下特权文件（正常系统文件）：
- SUID: /usr/lib/openssh/ssh-keysign
- SUID: /usr/lib/dbus-1.0/dbus-daemon-launch-helper
- SUID: /usr/bin/chfn
- SUID: /usr/bin/chsh
- SUID: /usr/bin/sudo
- SUID: /usr/bin/newgrp
- SUID: /usr/bin/mount
- SUID: /usr/bin/umount
- SUID: /usr/bin/fusermount3
- SUID: /usr/bin/su
- SUID: /usr/bin/gpasswd
- SUID: /usr/bin/passwd
- SUID: /var/lib/docker/rootfs/overlayfs/84d2de0f41d9c9fe6ef1ff7ea8c267234a7632d7e1b0ccfe51971aac89251479/bin/ping
- SUID: /var/lib/docker/rootfs/overlayfs/84d2de0f41d9c9fe6ef1ff7ea8c267234a7632d7e1b0ccfe51971aac89251479/usr/sbin/suexec
- SUID: /var/lib/docker/rootfs/overlayfs/480e996815a324b34c3f6062bea6b7bdfba4ef634fe216ddd2f8e86e862b4d1b/usr/bin/newgrp
- SUID: /var/lib/docker/rootfs/overlayfs/480e996815a324b34c3f6062bea6b7bdfba4ef634fe216ddd2f8e86e862b4d1b/usr/bin/umount
- SUID: /var/lib/docker/rootfs/overlayfs/480e996815a324b34c3f6062bea6b7bdfba4ef634fe216ddd2f8e86e862b4d1b/usr/bin/gpasswd
- SUID: /var/lib/docker/rootfs/overlayfs/480e996815a324b34c3f6062bea6b7bdfba4ef634fe216ddd2f8e86e862b4d1b/usr/bin/passwd
- SUID: /var/lib/docker/rootfs/overlayfs/480e996815a324b34c3f6062bea6b7bdfba4ef634fe216ddd2f8e86e862b4d1b/usr/bin/chfn
- SUID: /var/lib/docker/rootfs/overlayfs/480e996815a324b34c3f6062bea6b7bdfba4ef634fe216ddd2f8e86e862b4d1b/usr/bin/su
- SGID: /usr/bin/crontab
- SGID: /usr/bin/expiry
- SGID: /usr/bin/chage
- SGID: /usr/bin/ssh-agent
- SGID: /usr/sbin/unix_chkpwd
- SGID: /usr/sbin/pam_extrausers_chkpwd
- SGID: /usr/sbin/postdrop
- SGID: /usr/sbin/postqueue
- SGID: /var/lib/docker/rootfs/overlayfs/480e996815a324b34c3f6062bea6b7bdfba4ef634fe216ddd2f8e86e862b4d1b/usr/bin/chage
- SGID: /var/lib/docker/rootfs/overlayfs/480e996815a324b34c3f6062bea6b7bdfba4ef634fe216ddd2f8e86e862b4d1b/usr/bin/expiry
- SGID: /var/lib/docker/rootfs/overlayfs/480e996815a324b34c3f6062bea6b7bdfba4ef634fe216ddd2f8e86e862b4d1b/usr/bin/ssh-agent
- SGID: /var/lib/docker/rootfs/overlayfs/480e996815a324b34c3f6062bea6b7bdfba4ef634fe216ddd2f8e86e862b4d1b/usr/sbin/unix_chkpwd
- SGID: /var/lib/docker/rootfs/overlayfs/e4b7eea5a8cac0905da274dfb7e39ddf48299fda839bbcb9fe5bb699293fcd57/usr/sbin/unix_chkpwd
- SGID: /var/lib/docker/rootfs/overlayfs/e4b7eea5a8cac0905da274dfb7e39ddf48299fda839bbcb9fe5bb699293fcd57/usr/bin/expiry
- SGID: /var/lib/docker/rootfs/overlayfs/e4b7eea5a8cac0905da274dfb7e39ddf48299fda839bbcb9fe5bb699293fcd57/usr/bin/chage
- SGID: /var/lib/docker/rootfs/overlayfs/e4b7eea5a8cac0905da274dfb7e39ddf48299fda839bbcb9fe5bb699293fcd57/usr/bin/ssh-agent
- SGID: /var/lib/docker/rootfs/overlayfs/a1237304ad475d1c5a5a47c5f7d2fe3b47887a57e8197251bd317f844042323f/usr/sbin/unix_chkpwd
- SGID: /var/lib/docker/rootfs/overlayfs/a1237304ad475d1c5a5a47c5f7d2fe3b47887a57e8197251bd317f844042323f/usr/bin/expiry
- SGID: /var/lib/docker/rootfs/overlayfs/a1237304ad475d1c5a5a47c5f7d2fe3b47887a57e8197251bd317f844042323f/usr/bin/chage
- SGID: /var/lib/docker/rootfs/overlayfs/a1237304ad475d1c5a5a47c5f7d2fe3b47887a57e8197251bd317f844042323f/usr/bin/ssh-agent

**/tmp 目录可执行文件**：
✅ **正常**：未在临时目录发现可执行文件

**勒索病毒特征检测**：
✅ **正常**：未发现勒索病毒特征文件

### 👤 账户和登录安全

**最近登录记录（最近10次）**：
root     pts/7        192.168.0.60     Sat Jan 17 09:46    gone - no logout
root     pts/6        192.168.0.60     Sat Jan 17 09:46    gone - no logout
root     pts/5        192.168.0.60     Sat Jan 17 09:39    gone - no logout
root     pts/5        192.168.0.60     Sat Jan 17 09:23 - 09:39  (00:15)
root     pts/5        192.168.0.60     Sat Jan 17 09:22 - 09:23  (00:00)
root     pts/5        192.168.0.60     Sat Jan 17 09:22 - 09:22  (00:00)
root     pts/5        192.168.0.60     Sat Jan 17 09:17 - 09:22  (00:04)
root     pts/5        192.168.0.60     Sat Jan 17 09:16 - 09:17  (00:00)
root     pts/5        192.168.0.60     Sat Jan 17 09:16 - 09:16  (00:00)
root     pts/5        192.168.0.60     Sat Jan 17 09:14 - 09:16  (00:01)


**失败登录统计**：
最近失败登录次数：0
0

**当前登录用户**：

**新增用户检查（最近30天）**：
✅ **正常**：未发现可疑的新增用户

**sudo 使用日志（最近10次）**：
无最近的 sudo 记录

### 🛡️ 系统完整性

**/etc 目录最近变更（最近7天）**：
⚠️ **注意**：发现最近修改的配置文件
- /etc/ssh/sshd_config (3.2K, Jan)

**关键配置文件检查**：
- /etc/passwd: 权限 -rw-r--r--, 所有者 100000
- /etc/shadow: 权限 -rw-r-----, 所有者 100000
- /etc/sudoers: 权限 -r--r-----, 所有者 100000
- /etc/ssh/sshd_config: 权限 -rw-r--r--, 所有者 100000

---

**安全检查完成时间**: 2026-01-17 10:57:02
**检查工具**: 运维深度安全检查 v1.0
