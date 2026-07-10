const { google } = require('googleapis');
const fs = require('fs');
const yaml = require('yaml');

async function updateRemoteConfig() {
  try {
    // 1. Read version from pubspec.yaml
    const pubspecStr = fs.readFileSync('../pubspec.yaml', 'utf8');
    const pubspec = yaml.parse(pubspecStr);
    const fullVersion = pubspec.version;
    const version = fullVersion.split('+')[0];

    console.log(`Extracted version from pubspec.yaml: ${version}`);

    // 2. Authenticate using service account
    // The GitHub Action will dump the FIREBASE_SERVICE_ACCOUNT secret into this file
    const keyFilePath = 'firebase-service-account.json';
    
    if (!fs.existsSync(keyFilePath)) {
      throw new Error(`Service account file not found at ${keyFilePath}. Ensure the secret is provided.`);
    }

    const auth = new google.auth.GoogleAuth({
      keyFile: keyFilePath,
      scopes: ['https://www.googleapis.com/auth/firebase.remoteconfig'],
    });

    const client = await auth.getClient();
    const projectId = await auth.getProjectId();

    const url = `https://firebaseremoteconfig.googleapis.com/v1/projects/${projectId}/remoteConfig`;

    // 3. Fetch current config
    console.log(`Fetching current Remote Config template for project: ${projectId}...`);
    const getRes = await client.request({ url, method: 'GET' });
    const template = getRes.data;

    // 4. Update latest_app_version
    let updated = false;
    if (!template.parameters) template.parameters = {};
    
    if (!template.parameters.latest_app_version) {
      template.parameters.latest_app_version = {
        defaultValue: { value: version },
        description: "Latest available version of the app for forced updates"
      };
      updated = true;
      console.log(`Added parameter latest_app_version with value ${version}`);
    } else {
      const currentRemoteVersion = template.parameters.latest_app_version.defaultValue.value;
      if (currentRemoteVersion !== version) {
        template.parameters.latest_app_version.defaultValue.value = version;
        updated = true;
        console.log(`Updated parameter latest_app_version from ${currentRemoteVersion} to ${version}`);
      }
    }
    
    if (!updated) {
      console.log('Remote config latest_app_version is already up to date.');
      return;
    }

    // 5. Publish new config
    console.log('Publishing new Remote Config template...');
    await client.request({
      url,
      method: 'PUT',
      headers: {
        'If-Match': getRes.headers.etag
      },
      data: template
    });
    
    console.log('✅ Successfully updated Firebase Remote Config.');
  } catch (error) {
    console.error('❌ Failed to update Remote Config:', error);
    process.exit(1);
  }
}

updateRemoteConfig();
