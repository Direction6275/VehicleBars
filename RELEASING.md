# Releasing Vehicle Bars

Vehicle Bars uses [BigWigs Packager](https://github.com/BigWigsMods/packager), following Cooldown Companion's GitHub Actions release flow. Retail compatibility comes from `VehicleBars/VehicleBars.toc` (currently Interface `120100`). The installable archive contains one `VehicleBars/` folder, including its license and changelog. Repository documentation and local test/build files are excluded.

## One-time distribution setup

1. Create the Vehicle Bars projects on CurseForge and Wago and complete any platform approval requirements.
2. Add their actual IDs to `VehicleBars/VehicleBars.toc`:

   ```text
   ## X-Curse-Project-ID: YOUR_CURSEFORGE_PROJECT_ID
   ## X-Wago-ID: YOUR_WAGO_PROJECT_ID
   ```

   These IDs belong to Vehicle Bars. Do not copy Cooldown Companion's IDs. BigWigs reads them from the TOC; no duplicate IDs in `.pkgmeta` are needed.
3. In [GitHub Actions secrets](https://github.com/Direction6275/VehicleBars/settings/secrets/actions), add `CF_API_KEY` (the CurseForge upload API token) and `WAGO_API_TOKEN` (the Wago upload token). Use tokens whose accounts have upload access to the new projects. Existing secrets on Cooldown Companion cannot be copied or read back through GitHub.

   Alternatively, run these commands and paste each token at the hidden prompt:

   ```powershell
   gh secret set CF_API_KEY --repo Direction6275/VehicleBars
   gh secret set WAGO_API_TOKEN --repo Direction6275/VehicleBars
   ```

   Never put tokens in source files, commit messages, or project IDs. GitHub supplies its own release token automatically.
4. Commit and push the TOC IDs before creating a release tag.

The release workflow checks both IDs and both upload secrets before publishing. Until those are configured, use Package Preview to build a ZIP for testing or manual upload.

## Build a preview

Open [Package Preview](https://github.com/Direction6275/VehicleBars/actions/workflows/package-preview.yml), choose **Run workflow**, and download the `VehicleBars-<version>.zip` artifact from the completed run. This is the installable addon ZIP, with no outer archive to extract first. Preview runs never upload to CurseForge, Wago, or GitHub Releases and need no upload tokens.

```powershell
gh workflow run package-preview.yml --repo Direction6275/VehicleBars --ref main
```

## Publish a version

1. Update `CHANGELOG.md` with the notes for this release. Its contents become the release notes on all three destinations. Keep older notes in Git history.
2. Check Lua syntax and test the addon in game, especially combat vehicle entry/exit and clicking the HUD. Packaging success does not validate protected WoW behavior.
3. Commit and push to `main`, then run Package Preview and inspect the ZIP.
4. On GitHub, open **Releases > Draft a new release**, choose a new version tag targeting `main`, and click **Publish release**. Both `1.2` and `v1.2.0` style tags are supported. You can leave the notes blank; the packager uses the committed changelog.

Publishing a GitHub release starts **Package and Release**, which checks out that exact tag, uploads to CurseForge and Wago, and attaches the packaged ZIP to the GitHub release. Pushing a tag by itself does not publish; publish its GitHub release to start packaging. Draft releases do not start packaging.

BigWigs replaces `@project-version@` in the TOC and Lua with the tag-derived version. Untagged preview versions are development builds. The local checkout reports `1.2.0-dev`; update that debug fallback when beginning the next development version.

## Recover a release that did not run

For an existing release whose packaging never started, open **Actions > Package and Release > Run workflow**, select `main`, and enter the existing tag. The current workflow packages the original tag without moving or recreating it. For example:

```powershell
gh workflow run release.yml --repo Direction6275/VehicleBars --ref main -f tag=1.2
```

If a real release run failed after starting uploads, inspect its logs and each destination before retrying, since an upload may already have succeeded on another platform. Use Package Preview for build-only testing.

## Local installation

The working addon lives in the repository's `VehicleBars/` subfolder. The existing Retail AddOns symlink points there. The packaging setup preserves that layout; GitHub source archives are not installable addon release ZIPs.
