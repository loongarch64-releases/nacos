#!/bin/bash
set -euo pipefail

SRC="${1}"
VERSION="${2}"
IFS=. read -r major_ver minor_ver patch_ver <<< "$VERSION"
ver_num=$(( 10#$major_ver * 1000000 + 10#$minor_ver * 1000 + 10#$patch_ver ))

# 插件：protoc_gen_grpc_java
grpc_java_ver=$(sed -n 's#.*<grpc-java\.version>\([0-9]\+\.[0-9]\+\.[0-9]\+\)</grpc-java\.version>.*#\1#p' "${SRC}/pom.xml")
protoc_gen_grpc_java_dir="${HOME}/.m2/repository/io/grpc/protoc-gen-grpc-java/${grpc_java_ver}"
mkdir -p "${protoc_gen_grpc_java_dir}"
wget -P "${protoc_gen_grpc_java_dir}" "https://github.com/loongarch64-releases/grpc-java/releases/download/v${grpc_java_ver}/protoc-gen-grpc-java-${grpc_java_ver}-linux-loongarch_64.exe"  

# 添加 maven repo
cat << 'EOF' > /tmp/insert_block
        <profile>
            <id>loongarch64</id>
            <activation>
                <os>
                    <family>unix</family>
                    <arch>loongarch64</arch>
                </os>
            </activation>
            <repositories>
                <repository>
                    <id>loongnix-maven</id>
                    <url>https://maven.loongnix.cn/loongarch/maven</url>
                </repository>
            </repositories>
        </profile>
EOF
sed -i '/<profiles>/r /tmp/insert_block' "${SRC}/pom.xml"

# 适配旧版本
if [ "${ver_num}" -lt 3002000 ]; then
    sed -i '/os-maven-plugin/,/<\/version>/ s/<version>.*/<version>1.7.1<\/version>/' "${SRC}/istio/pom.xml"
fi

