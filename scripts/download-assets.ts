import axios from "axios";
import fs from "fs";
import { resolve } from "path";

const ASSET_BASE_PATH = resolve(__dirname, "..", "assets");

type Release = {
  url: string;
  html_url: string;
  assets_url: string;
  upload_url: string;
  tarball_url: string;
  zipball_url: string;
  id: number;
  node_id: string;
  tag_name: string;
  target_commitish: string;
  name: string;
  body: string;
  draft: boolean;
  prerelease: boolean;
  created_at: string;
  published_at: string;
  author: string;
  assets: ReleaseAsset[];
};

type ReleaseAsset = {
  url: string;
  id: number;
  node_id: string;
  name: string;
  label: string | null;
  uploader: any;
  content_type: string;
  state: string;
  size: number;
  download_count: number;
  created_at: string;
  updated_at: string;
  browser_download_url: string;
};

async function downloadAsset(asset: ReleaseAsset) {
  console.log(`⬇️  Downloading file "${asset.name}...`);
  const url = asset.browser_download_url;
  const path = resolve(ASSET_BASE_PATH, asset.name);
  const writer = fs.createWriteStream(path);

  const response = await axios({
    url,
    method: "GET",
    responseType: "stream"
  });

  response.data.pipe(writer);

  return new Promise((success, failure) => {
    writer.on("finish", () => {
      console.log(`✅  Downloaded file "${asset.name}"!`);
      success();
    });
    writer.on("error", failure);
  });
}

async function downloadRelease(baseURL: string) {
  // TODO: support downloading other versions
  const url = baseURL + "/latest";
  const { data }: { data: Release } = await axios.get(url);

  // Create "./assets" folder in case it doesn't exist.
  if (!fs.existsSync(ASSET_BASE_PATH)) {
    fs.mkdirSync(ASSET_BASE_PATH);
  }

  // Download each release in parallel
  await Promise.all(data.assets.map(asset => downloadAsset(asset)));

  console.log(`👍  Downloaded all releases from "${url}"`);
}

// Download connectd releases
async function downloadAll() {
  await Promise.all([
    downloadRelease("https://api.github.com/repos/remoteit/connectd/releases"),
    downloadRelease(
      "https://api.github.com/repos/remoteit/Server-Channel/releases"
    )
  ]);

  console.log(`🎉  Downloaded all files to "./assets"`);
}

// Download everything!
downloadAll();
