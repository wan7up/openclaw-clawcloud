import fs from "node:fs";
import path from "node:path";

const configPath = path.resolve(process.cwd(), "config/users.json");

export function loadProfiles() {
  const raw = fs.readFileSync(configPath, "utf8");
  const data = JSON.parse(raw);
  return data?.users ?? {};
}

export function getUserProfile(userId) {
  const users = loadProfiles();
  const profile = users[userId];
  if (!profile || profile.enabled !== true) return null;
  return { userId, ...profile };
}
