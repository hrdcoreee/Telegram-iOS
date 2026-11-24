#import "SGLitePerfPrefsController.h"
#import "SGLitePerfSettings.h"

typedef NS_ENUM(NSInteger, SGLiteRowType) {
    SGLiteRowMasterEnable = 0,
    SGLiteRowDisableBlurAndGlass,
    SGLiteRowForceLowPower,
    SGLiteRowThrottleParticles,
    SGLiteRowDisableOffscreenShadows,
    SGLiteRowDisableGalleryLiveCamera,
    SGLiteRowHideGalleryCamera,
    SGLiteRowDisableSwipeToStory,
    SGLiteRowDisableSnapDeletion,
    SGLiteRowRestartApp
};

@interface SGLitePerfPrefsController ()
@property (nonatomic, assign) BOOL isRussian;
@end

@implementation SGLitePerfPrefsController

static UIWindow *SGLiteFindActiveKeyWindow(void) {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]] &&
            (scene.activationState == UISceneActivationStateForegroundActive ||
             scene.activationState == UISceneActivationStateForegroundInactive)) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow && !window.isHidden) {
                    return window;
                }
            }
            for (UIWindow *window in windowScene.windows) {
                if (!window.isHidden) {
                    return window;
                }
            }
        }
    }
    return nil;
}

static UIViewController *SGLiteTopViewController(UIViewController *root) {
    UIViewController *current = root;
    while (current.presentedViewController && !current.presentedViewController.isBeingDismissed) {
        current = current.presentedViewController;
    }
    return current;
}

+ (void)presentFromTopViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = SGLiteFindActiveKeyWindow();
        if (!window || !window.rootViewController) {
            return;
        }
        UIViewController *topVC = SGLiteTopViewController(window.rootViewController);
        if ([topVC isKindOfClass:[UINavigationController class]] &&
            [[(UINavigationController *)topVC topViewController] isKindOfClass:[SGLitePerfPrefsController class]]) {
            return;
        }

        SGLitePerfPrefsController *vc = [[SGLitePerfPrefsController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        if (@available(iOS 15.0, *)) {
            nav.modalPresentationStyle = UIModalPresentationPageSheet;
        }
        [topVC presentViewController:nav animated:YES completion:nil];
    });
}

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        NSString *lang = [NSLocale preferredLanguages].firstObject ?: @"en";
        _isRussian = [lang hasPrefix:@"ru"] || [lang hasPrefix:@"uk"] || [lang hasPrefix:@"be"];
    }
    return self;
}

- (NSString *)t:(NSString *)ru en:(NSString *)en {
    return self.isRussian ? ru : en;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"SGLitePerf";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                             target:self
                             action:@selector(dismissSelf)];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 56.0;
}

- (void)dismissSelf {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table Structure

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 1; // Master toggle
        case 1: return 4; // Graphics & Animations
        case 2: return 4; // Camera & Swiftgram Extras
        case 3: return 1; // Restart button
        default: return 0;
    }
}

- (SGLiteRowType)rowTypeForIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return SGLiteRowMasterEnable;
        case 1:
            switch (indexPath.row) {
                case 0: return SGLiteRowDisableBlurAndGlass;
                case 1: return SGLiteRowForceLowPower;
                case 2: return SGLiteRowThrottleParticles;
                default: return SGLiteRowDisableOffscreenShadows;
            }
        case 2:
            switch (indexPath.row) {
                case 0: return SGLiteRowDisableGalleryLiveCamera;
                case 1: return SGLiteRowHideGalleryCamera;
                case 2: return SGLiteRowDisableSwipeToStory;
                default: return SGLiteRowDisableSnapDeletion;
            }
        default:
            return SGLiteRowRestartApp;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [self t:@"Общее" en:@"General"];
        case 1:
            return [self t:@"Графика, блюр и анимации" en:@"Graphics, Blur & Animations"];
        case 2:
            return [self t:@"Камера и эффекты" en:@"Camera & Effects"];
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    SGLitePerfSettings *s = [SGLitePerfSettings shared];
    if (section == 0) {
        NSString *profile = s.isOlderDeviceDetected
            ? [self t:@"Определено слабое/старое устройство — оптимизации рекомендованы." en:@"Older/low-RAM device detected — optimizations recommended."]
            : [self t:@"Современное устройство." en:@"Modern device detected."];
        return [NSString stringWithFormat:@"%@\n%@", s.deviceSummary, profile];
    }
    if (section == 3) {
        return [self t:@"После изменения настроек прозрачности/камеры перезапустите приложение, чтобы сбросить кэшированные слои."
                       en:@"Restart the app after changing transparency/camera toggles to apply cached layer states."];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SGLiteRowType rowType = [self rowTypeForIndexPath:indexPath];
    SGLitePerfSettings *s = [SGLitePerfSettings shared];

    if (rowType == SGLiteRowRestartApp) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text = [self t:@"Перезапустить приложение" en:@"Restart App"];
        cell.textLabel.textColor = [UIColor systemRedColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        return cell;
    }

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];

    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.tag = rowType;
    [toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

    BOOL enabled = s.tweakEnabled;

    switch (rowType) {
        case SGLiteRowMasterEnable:
            cell.textLabel.text = [self t:@"Включить SGLitePerf" en:@"Enable SGLitePerf"];
            cell.detailTextLabel.text = [self t:@"Глобальный переключатель всех оптимизаций" en:@"Master switch for all performance tweaks"];
            toggle.on = s.tweakEnabled;
            toggle.enabled = YES;
            break;
        case SGLiteRowDisableBlurAndGlass:
            cell.textLabel.text = [self t:@"Отключить блюр и стекло (Flat UI)" en:@"Disable Blur & Glass (Flat UI)"];
            cell.detailTextLabel.text = [self t:@"Убирает CABackdropLayer, 3D meshTransform, UIGlassEffect и блюр дат в чате" en:@"Disables CABackdropLayer, 3D meshTransform, UIGlassEffect & chat date blurs"];
            toggle.on = s.disableBlurAndGlass;
            toggle.enabled = enabled;
            break;
        case SGLiteRowForceLowPower:
            cell.textLabel.text = [self t:@"Облегчённые эмодзи (30 FPS)" en:@"Low-Power Emoji & Animations (30 FPS)"];
            cell.detailTextLabel.text = [self t:@"Включает frame-skip (30 FPS) для кастомных эмодзи и снижает фоновую нагрузку" en:@"Enables 30 FPS frame-skip for custom emoji renderers and reduces background work"];
            toggle.on = s.forceLowPowerOptimizations;
            toggle.enabled = enabled;
            break;
        case SGLiteRowThrottleParticles:
            cell.textLabel.text = [self t:@"Ограничить частицы (спойлеры / звёзды)" en:@"Throttle Particle Emitters"];
            cell.detailTextLabel.text = [self t:@"Уменьшает частоту генерации частиц CAEmitterLayer на 75%" en:@"Reduces CAEmitterLayer particle birth rate by 75%"];
            toggle.on = s.throttleParticles;
            toggle.enabled = enabled;
            break;
        case SGLiteRowDisableOffscreenShadows:
            cell.textLabel.text = [self t:@"Убрать тяжёлые тени (Shadow Pass)" en:@"Disable Uncached Shadows"];
            cell.detailTextLabel.text = [self t:@"Убирает оффскрин-тени в SwiftUI-тулбаре и кнопках" en:@"Removes expensive offscreen shadows in SwiftUI toolbars & buttons"];
            toggle.on = s.disableOffscreenShadows;
            toggle.enabled = enabled;
            break;
        case SGLiteRowDisableGalleryLiveCamera:
            cell.textLabel.text = [self t:@"Отключить живую камеру в галерее" en:@"Disable Live Camera in Gallery"];
            cell.detailTextLabel.text = [self t:@"Предотвращает фоновый запуск AVCaptureSession при открытии скрепки" en:@"Stops live AVCaptureSession preview when opening photo picker"];
            toggle.on = s.disableGalleryLiveCamera;
            toggle.enabled = enabled;
            break;
        case SGLiteRowHideGalleryCamera:
            cell.textLabel.text = [self t:@"Скрыть ячейку камеры в галерее (Swiftgram)" en:@"Hide Gallery Camera Cell (Swiftgram)"];
            cell.detailTextLabel.text = [self t:@"Полностью убирает плитку камеры из сетки выбора фото" en:@"Removes the camera tile from the media picker grid"];
            toggle.on = s.hideGalleryCamera;
            toggle.enabled = enabled;
            break;
        case SGLiteRowDisableSwipeToStory:
            cell.textLabel.text = [self t:@"Отключить свайп на камеру историй (Swiftgram)" en:@"Disable Swipe to Story Camera (Swiftgram)"];
            cell.detailTextLabel.text = [self t:@"Убирает случайное открытие камеры при свайпе списка чатов" en:@"Prevents opening story camera on chat list swipe"];
            toggle.on = s.disableSwipeToStoryCamera;
            toggle.enabled = enabled;
            break;
        case SGLiteRowDisableSnapDeletion:
            cell.textLabel.text = [self t:@"Отключить анимацию рассыпания сообщений" en:@"Disable Message Snap Deletion Effect"];
            cell.detailTextLabel.text = [self t:@"Убирает ресурсоёмкую анимацию частиц при удалении" en:@"Skips heavy particle dissolve animation on delete"];
            toggle.on = s.disableSnapDeletionEffect;
            toggle.enabled = enabled;
            break;
        default:
            break;
    }

    cell.accessoryView = toggle;
    return cell;
}

- (void)switchChanged:(UISwitch *)sender {
    SGLitePerfSettings *s = [SGLitePerfSettings shared];
    BOOL val = sender.isOn;
    switch ((SGLiteRowType)sender.tag) {
        case SGLiteRowMasterEnable:
            s.tweakEnabled = val;
            [self.tableView reloadData];
            break;
        case SGLiteRowDisableBlurAndGlass:
            s.disableBlurAndGlass = val;
            break;
        case SGLiteRowForceLowPower:
            s.forceLowPowerOptimizations = val;
            break;
        case SGLiteRowThrottleParticles:
            s.throttleParticles = val;
            break;
        case SGLiteRowDisableOffscreenShadows:
            s.disableOffscreenShadows = val;
            break;
        case SGLiteRowDisableGalleryLiveCamera:
            s.disableGalleryLiveCamera = val;
            break;
        case SGLiteRowHideGalleryCamera:
            s.hideGalleryCamera = val;
            break;
        case SGLiteRowDisableSwipeToStory:
            s.disableSwipeToStoryCamera = val;
            break;
        case SGLiteRowDisableSnapDeletion:
            s.disableSnapDeletionEffect = val;
            break;
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self rowTypeForIndexPath:indexPath] == SGLiteRowRestartApp) {
        [[NSUserDefaults standardUserDefaults] synchronize];
        exit(0);
    }
}

@end
