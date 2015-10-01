#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/android"

file=build.gradle
cat "$file" | awk '
	{
		print $0
		if (compile == 1) {
			sub("[^ ].*", "compile('\''com.crashlytics.sdk.android:crashlytics:2.5.2@aar'\'') { transitive = true }")
			print $0
			compile=0
		}
	}
	/apply plugin:/ {
		sub("[^ ].*", "apply plugin: '\''io.fabric'\''")
		print $0
	}
	/mavenCentral/ {
		sub("[^ ].*", "maven { url '\''https://maven.fabric.io/public'\'' }")
		print $0
	}
	/classpath/ {
		sub("[^ ].*", "classpath '\''io.fabric.tools:gradle:1.+'\''")
		print $0
	}
	/^dependencies / {
		compile=1
	}
' > "${file}.tmp"
mv -vf "${file}.tmp" "$file"

release_note=fabric-release.note
if [ -z "${IS_CI:-}" ]
then
	echo "Send from local PC" > $release_note
else
	git log --format=%B -n 1 $TRAVIS_COMMIT > $release_note
fi
cat <<EOF > fabric.properties
apiSecret=$FABRIC_BUILD_SECRET
apiKey=$FABRIC_API_KEY
betaDistributionReleaseNotesFilePath=$release_note
betaDistributionGroupAliases=$CRASHLYTICS_GROUPS
EOF

find src -name 'MainActivity.java' | while read file
do
	cat "$file" | awk '
		{print $0}
		/super.onCreate/ {
			sub("super.*", "io.fabric.sdk.android.Fabric.with(this, new com.crashlytics.android.Crashlytics());");
			print $0
		}
	' > "${file}.tmp"
	mv -vf "${file}.tmp" "$file"
done

