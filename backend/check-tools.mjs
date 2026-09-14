import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { findTool } from './src/processor.mjs';
const exec = promisify(execFile);
let unavailable = false;
for (const tool of ['ffprobe', 'ffmpeg']) {
  try {
    const { stdout } = await exec(findTool(tool), ['-version'], { timeout: 10000, windowsHide: true });
    console.log(stdout.split(/\r?\n/)[0]);
  } catch {
    unavailable = true;
    console.error(`${tool}不可用；请设置HILDORS_${tool.toUpperCase()}为已安装工具的绝对路径。`);
  }
}
process.exitCode = unavailable ? 1 : 0;
