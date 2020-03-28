declare let Multibar_EmptyFunc: any;
declare let MultiActionBar_Update: any;
declare let MultiActionBar_UpdateGrid: any;
declare let ShowBonusActionBar: any;

const noop = Multibar_EmptyFunc;
MultiActionBar_Update = noop
MultiActionBar_UpdateGrid = noop
ShowBonusActionBar = noop

UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarRight'] = null;
UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarLeft'] = null;
UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomLeft'] = null;
UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomRight'] = null;
UIPARENT_MANAGED_FRAME_POSITIONS['MainMenuBar'] = null;
UIPARENT_MANAGED_FRAME_POSITIONS['ShapeshiftBarFrame'] = null;
UIPARENT_MANAGED_FRAME_POSITIONS['PossessBarFrame'] = null;
UIPARENT_MANAGED_FRAME_POSITIONS['PETACTIONBAR_YPOS'] = null;

MainMenuBar.UnregisterAllEvents();
MainMenuBar.Show = noop;
MainMenuBar.Hide();

// MainMenuBarArtFrame.UnregisterEvent('PLAYER_ENTERING_WORLD')
// MainMenuBarArtFrame.UnregisterEvent('BAG_UPDATE') // needed to display stuff on the backpack button
// MainMenuBarArtFrame.UnregisterEvent('ACTIONBAR_PAGE_CHANGED')
// //      MainMenuBarArtFrame.UnregisterEvent('KNOWN_CURRENCY_TYPES_UPDATE') --needed to display the token tab
// //      MainMenuBarArtFrame.UnregisterEvent('CURRENCY_DISPLAY_UPDATE')
// MainMenuBarArtFrame.UnregisterEvent('ADDON_LOADED')
// MainMenuBarArtFrame.Hide()


// MainMenuExpBar.UnregisterAllEvents()
// MainMenuExpBar.Hide()

// ShapeshiftBarFrame.UnregisterAllEvents()
// ShapeshiftBarFrame.Hide()

// BonusActionBarFrame.UnregisterAllEvents()
// BonusActionBarFrame.Hide()

// PossessBarFrame.UnregisterAllEvents()
// PossessBarFrame.Hide()

// hooksecurefunc('TalentFrame_LoadUI', function()
// 	PlayerTalentFrame.UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
// end)
