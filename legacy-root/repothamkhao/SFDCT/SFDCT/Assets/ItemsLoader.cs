using Microsoft.Xna.Framework.Graphics;
using SFD;
using SFD.Code;
using SFD.Tiles;

namespace SFDCT.Assets;

internal static class ItemsLoader
{
    internal static Item LoadFolderItem(GameSFD game, string folderPath, string iniPath)
    {
        var propertiesHandler = new IniHandler();
        propertiesHandler.ReadFile(iniPath);

        var itemParts = new List<ItemPart>();
        var itemGameName = propertiesHandler.ReadValue("GameName");
        var itemFileName = propertiesHandler.ReadValue("FileName");
        var itemEquipmentLayer = propertiesHandler.ReadValueInt("EquipmentLayer", 0);
        var itemID = propertiesHandler.ReadValue("ID");
        var itemJacketUnderBelt = propertiesHandler.ReadValueBool("JacketUnderBelt", false);
        var itemCanEquip = propertiesHandler.ReadValueBool("CanEquip", false);
        var itemCanScript = propertiesHandler.ReadValueBool("CanScript", false);
        var itemColorPalette = propertiesHandler.ReadValue("ColorPalette");

        // this is specific to 'DeluxeBench' exports
        itemID ??= propertiesHandler.ReadValue("ItemID");
        itemFileName ??= Path.GetFileNameWithoutExtension(iniPath);
        if (propertiesHandler.ReadValue("JacketUnderBelt") == "true") itemJacketUnderBelt = true;
        if (propertiesHandler.ReadValue("CanEquip") == "true") itemCanEquip = true;
        if (propertiesHandler.ReadValue("CanScript") == "true") itemCanScript = true;

        if (itemGameName == null || itemFileName == null || itemID == null || itemColorPalette == null)
        {
            ConsoleOutput.ShowMessage(ConsoleOutputType.Error, $"Error reading equipment folder, missing properties: GameName='{itemGameName}', FileName='{itemFileName}', ID='{itemID}', ColorPalette='{itemColorPalette}'");

            return null;
        }

        var imageFilePaths = Directory.EnumerateFiles(folderPath, "*.png");
        var texturesByIDs = new Dictionary<int, Texture2D[]>();

        foreach (var imageFilePath in imageFilePaths)
        {
            var imageName = Path.GetFileNameWithoutExtension(imageFilePath);
            var imageNameBits = imageName.Split('_');

            int partTypeID;
            int partLocalID;
            if (!int.TryParse(imageNameBits[0], out partTypeID) || !int.TryParse(imageNameBits[1], out partLocalID)) continue;

            var texture = Textures.m_tileTextures.PremultiplyTexture(imageFilePath, game.GraphicsDevice);
            if (texture == null) continue;

            if (!texturesByIDs.TryGetValue(partTypeID, out Texture2D[] value))
            {
                value = new Texture2D[ItemPart.TYPE.PART_RANGE];
                texturesByIDs.Add(partTypeID, value);
            }

            value[partLocalID] = texture;
            Item.LoadedItemTextureParts++;
        }

        foreach (var kvp in texturesByIDs)
        {
            // TODO:
            // add logic to process the textures and create ItemPart.AnalyzeData,
            // for now SFD accepts null, but that might change later?
            var itemPart = new ItemPart(kvp.Value, null, kvp.Key, itemID);

            itemParts.Add(itemPart);
        }

        return new Item(itemParts.ToArray(), null, itemGameName, itemFileName, itemEquipmentLayer, itemID, itemJacketUnderBelt, itemCanEquip, itemCanScript, itemColorPalette);
    }

    internal static bool Load(GameSFD game)
    {
        // Items vanilla setup
        Items.m_allItems = [];
        Items.m_allFemaleItems = [];
        Items.m_allMaleItems = [];

        Items.m_slotAllItems = new List<Item>[Equipment.TOTAL_INTERNAL_LAYERS];
        Items.m_slotFemaleItems = new List<Item>[Equipment.TOTAL_INTERNAL_LAYERS];
        Items.m_slotMaleItems = new List<Item>[Equipment.TOTAL_INTERNAL_LAYERS];

        for (int i = 0; i < Equipment.TOTAL_INTERNAL_LAYERS; i++)
        {
            Items.m_slotAllItems[i] = [];
            Items.m_slotFemaleItems[i] = [];
            Items.m_slotMaleItems[i] = [];
        }

        var loadedIDs = new HashSet<string>();
        var contents = SubContent.GetContents().Where(content => Directory.Exists(Path.Combine(content.Directory, SFDPaths.DATA_ITEMS))).Reverse();

        foreach (var content in contents)
        {
            var contentItemsFolderPath = Path.Combine(content.Directory, SFDPaths.DATA_ITEMS);
            var current = 0;
            var total = 0;
            var semaphore = new SemaphoreSlim(1);

            // TODO:
            // merge these 2 to re use the same code so its not duplicated twice

            var folderItems = Directory.EnumerateFiles(contentItemsFolderPath, "*.ini", SearchOption.AllDirectories);

            current = 0;
            total = folderItems.Count();

            game.SetLoadingProgress(current, total);

            Parallel.ForEach(folderItems, delegate (string path)
            {
                if (CoreConstants.Closing) return;

                var item = LoadFolderItem(game, Path.GetDirectoryName(path), path);
                item.PostProcess();

                try
                {
                    semaphore.Wait();
                    Interlocked.Increment(ref current);
                    game.SetLoadingProgress(current, total);

                    if (!loadedIDs.Add(item.ID))
                    {
                        var conflictingItem = Items.GetItem(item.ID);

                        if (conflictingItem != null)
                        {
                            throw new Exception($"Error: Item ID collision between item '{conflictingItem}' and '{item}' while loading '{path}'");
                        }
                        else
                        {
                            throw new Exception($"Error: Item ID collision, item with ID '{item.ID}' has already been loaded, cannot load item '{item}' from '{path}'");
                        }
                    }

                    Items.m_allItems.Add(item);
                    Items.m_slotAllItems[item.EquipmentLayer].Add(item);
                }
                finally
                {
                    semaphore.Release();
                }
            });

            semaphore.Wait();
            semaphore.Release();
            game.SetLoadingProgress(0, 0);

            //

            var items = Directory.EnumerateFiles(contentItemsFolderPath, "*.item", SearchOption.AllDirectories);
            current = 0;
            total = items.Count();

            game.SetLoadingProgress(current, total);

            Parallel.ForEach(items, delegate (string path)
            {
                if (CoreConstants.Closing) return;

                var item = ContentLoader.Load<Item>(path);
                item.PostProcess();

                try
                {
                    semaphore.Wait();
                    Interlocked.Increment(ref current);
                    game.SetLoadingProgress(current, total);

                    if (!loadedIDs.Add(item.ID))
                    {
                        var conflictingItem = Items.GetItem(item.ID);

                        if (conflictingItem != null)
                        {
                            throw new Exception($"Error: Item ID collision between item '{conflictingItem}' and '{item}' while loading '{path}'");
                        }
                        else
                        {
                            throw new Exception($"Error: Item ID collision, item with ID '{item.ID}' has already been loaded, cannot load item '{item}' from '{path}'");
                        }
                    }

                    Items.m_allItems.Add(item);
                    Items.m_slotAllItems[item.EquipmentLayer].Add(item);
                }
                finally
                {
                    semaphore.Release();
                }
            });

            semaphore.Release();
            game.SetLoadingProgress(0, 0);
        }

        Items.PostProcessGenders();

        Player.HurtLevel1 = Items.GetItem("HurtLevel1");
        Player.HurtLevel2 = Items.GetItem("HurtLevel2");
        Player.HurtLevel2 ??= Player.HurtLevel1;

        Items.IsLoaded = true;
        return true;
    }
}
