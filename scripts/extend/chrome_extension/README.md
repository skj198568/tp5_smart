# Selenium Chrome HTTP Private Proxy

This plugin permit to use proxy with a basic authentication with Chrome and Selenium ([it's impossible](http://docs.seleniumhq.org/docs/04_webdriver_advanced.jsp#using-a-proxy)).
This trick can be use for all basic auth in your test with Selenium and Chrome.

Thanks to [henices](https://github.com/henices/Chrome-proxy-helper) who codes Chrome Proxy Helper. This fork uses it code base.

This plugin is maintained by [Robin (PHP developer in Marseille)](http://www.robin-d.fr/). Report your issues with Github.

## How to use it

I use webDriver with a PHP client. So, this example will be in PHP.
**The logic is the same with another language (java, python... same protocol).**
```php
$pluginForProxyLogin = '/tmp/a'.uniqid().'.zip';

$zip = new ZipArchive();
$res = $zip->open($pluginForProxyLogin, ZipArchive::CREATE | ZipArchive::OVERWRITE);
$zip->addFile('/path/to/Chrome-proxy-helper/manifest.json', 'manifest.json');
$background = file_get_contents('/path/to/Chrome-proxy-helper/background.js');
$background = str_replace(['%proxy_host', '%proxy_port', '%username', '%password'], ['5.39.64.181', '54991', 'd1g1m00d', '13de02d0e0z9'], $background);
$zip->addFromString('background.js', $background);
$zip->close();

putenv("webdriver.chrome.driver=/path/to/chromedriver");

$options = new ChromeOptions();
$options->addExtensions([$pluginForProxyLogin]);
$caps = DesiredCapabilities::chrome();
$caps->setCapability(ChromeOptions::CAPABILITY, $options);

$driver = ChromeDriver::start($caps);
$driver->get('https://old-linux.com/ip/');

header('Content-Type: image/png');
echo $driver->takeScreenshot();


unlink($pluginForProxyLogin);
```
