import * as fs from 'fs'
import * as path from 'path'

export type WidgetFiles = {
  swiftFiles: string[]
  entitlementFiles: string[]
  plistFiles: string[]
  assetDirectories: string[]
  intentFiles: string[]
  otherFiles: string[]
}

export function getWidgetFiles(targetPath: string) {
  let packagePath
  try {
    packagePath = path.dirname(require.resolve('expo-live-activity/package.json'))
  } catch {
    console.log('Building for example app')
  }
  const liveActivityFilesPath = path.join(packagePath ? packagePath : '..', '/ios-files')
  const imageAssetsPath = './assets/liveActivity'

  const widgetFiles: WidgetFiles = {
    swiftFiles: [],
    entitlementFiles: [],
    plistFiles: [],
    assetDirectories: [],
    intentFiles: [],
    otherFiles: [],
  }

  if (!fs.existsSync(targetPath)) {
    fs.mkdirSync(targetPath, { recursive: true })
  }

  if (fs.lstatSync(liveActivityFilesPath).isDirectory()) {
    const files = fs.readdirSync(liveActivityFilesPath)

    files.forEach((file) => {
      const fileExtension = file.split('.').pop()

      if (fileExtension === 'swift') {
        widgetFiles.swiftFiles.push(file)
      } else if (fileExtension === 'entitlements') {
        widgetFiles.entitlementFiles.push(file)
      } else if (fileExtension === 'plist') {
        widgetFiles.plistFiles.push(file)
      } else if (fileExtension === 'xcassets') {
        widgetFiles.assetDirectories.push(file)
      } else if (fileExtension === 'intentdefinition') {
        widgetFiles.intentFiles.push(file)
      } else {
        widgetFiles.otherFiles.push(file)
      }
    })
  }

  // Copy files
  ;[
    ...widgetFiles.swiftFiles,
    ...widgetFiles.entitlementFiles,
    ...widgetFiles.plistFiles,
    ...widgetFiles.intentFiles,
    ...widgetFiles.otherFiles,
  ].forEach((file) => {
    const source = path.join(liveActivityFilesPath, file)
    copyFileSync(source, targetPath)
  })

  // Copy assets directory
  const imagesXcassetsSource = path.join(liveActivityFilesPath, 'Assets.xcassets')
  copyFolderRecursiveSync(imagesXcassetsSource, targetPath)

  // Move images to assets directory
  if (fs.existsSync(imageAssetsPath) && fs.lstatSync(imageAssetsPath).isDirectory()) {
    const imagesXcassetsTarget = path.join(targetPath, 'Assets.xcassets')

    const files = fs.readdirSync(imageAssetsPath)

    // Group images by base name
    const imageGroups: { [key: string]: { filename: string; scale: string }[] } = {}

    files.forEach((file) => {
      if (path.extname(file).match(/\.(png|jpg|jpeg)$/)) {
        // Extract base name and scale from filename
        const fileNameWithoutExt = path.basename(file, path.extname(file))
        const scaleMatch = fileNameWithoutExt.match(/^(.+?)(@2x|@3x)?$/)

        if (scaleMatch) {
          const baseName = scaleMatch[1]
          const scaleSuffix = scaleMatch[2] || ''
          const scale = scaleSuffix === '@2x' ? '2x' : scaleSuffix === '@3x' ? '3x' : '1x'

          if (!imageGroups[baseName]) {
            imageGroups[baseName] = []
          }

          imageGroups[baseName].push({ filename: file, scale })
        }
      }
    })

    // Process each image group
    Object.entries(imageGroups).forEach(([baseName, images]) => {
      const imageSetDir = path.join(imagesXcassetsTarget, `${baseName}.imageset`)

      // Create the .imageset directory if it doesn't exist
      if (!fs.existsSync(imageSetDir)) {
        fs.mkdirSync(imageSetDir, { recursive: true })
      }

      // Copy all image files to the .imageset directory
      images.forEach(({ filename }) => {
        const source = path.join(imageAssetsPath, filename)
        const destPath = path.join(imageSetDir, filename)
        fs.copyFileSync(source, destPath)
      })

      // Create Contents.json with all scales
      const contentsJson = {
        images: [
          {
            filename: images.find((img) => img.scale === '1x')?.filename,
            idiom: 'universal',
            scale: '1x',
          },
          {
            filename: images.find((img) => img.scale === '2x')?.filename,
            idiom: 'universal',
            scale: '2x',
          },
          {
            filename: images.find((img) => img.scale === '3x')?.filename,
            idiom: 'universal',
            scale: '3x',
          },
        ].filter((img) => img.filename !== undefined),
        info: {
          author: 'xcode',
          version: 1,
        },
      }

      fs.writeFileSync(path.join(imageSetDir, 'Contents.json'), JSON.stringify(contentsJson, null, 2))
    })
  } else {
    console.warn(
      `Warning: Skipping adding images to live activity because directory does not exist at path: ${imageAssetsPath}`
    )
  }

  return widgetFiles
}

export function copyFileSync(source: string, target: string) {
  let targetFile = target

  if (fs.existsSync(target) && fs.lstatSync(target).isDirectory()) {
    targetFile = path.join(target, path.basename(source))
  }

  fs.writeFileSync(targetFile, fs.readFileSync(source))
}

function copyFolderRecursiveSync(source: string, target: string) {
  const targetPath = path.join(target, path.basename(source))
  if (!fs.existsSync(targetPath)) {
    fs.mkdirSync(targetPath, { recursive: true })
  }

  if (fs.lstatSync(source).isDirectory()) {
    const files = fs.readdirSync(source)
    files.forEach((file) => {
      const currentPath = path.join(source, file)
      if (fs.lstatSync(currentPath).isDirectory()) {
        copyFolderRecursiveSync(currentPath, targetPath)
      } else {
        copyFileSync(currentPath, targetPath)
      }
    })
  }
}
