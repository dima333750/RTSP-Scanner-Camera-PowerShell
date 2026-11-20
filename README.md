# RTSP-Scanner-Camera---PowerShell
<h1>PowerShell RTSP Network Scanner / PowerShell RTSP-сканер сети</h1>

<p><strong>[EN]</strong> A lightweight multi-threaded PowerShell diagnostic utility for discovering and inventorying RTSP video streams (IP cameras, NVRs) within a local network.<br>
<strong>[RU]</strong> Легковесная многопоточная диагностическая утилита на PowerShell для поиска и инвентаризации RTSP-видеопотоков (IP-камер, видеорегистраторов) в локальной сети.</p>

<hr>

<h2>English</h2>

<h3>Overview &amp; Features</h3>
<p>This script is a <strong>network diagnostic and inventory tool</strong> designed for system administrators and device owners to locate active RTSP endpoints and verify stream availability without installing third-party software.</p>
<ul>
  <li><strong>Fast Multi-threaded Scan:</strong> Uses PowerShell Runspaces to scan a <code>/24</code> subnet in seconds.</li>
  <li><strong>Protocol &amp; Path Verification:</strong> Checks common RTSP ports (<code>554</code>, <code>8554</code>, etc.) using standard <code>OPTIONS</code> and <code>DESCRIBE</code> requests.</li>
  <li><strong>Flexible &amp; Secure Authentication:</strong> Supports Basic and Digest RTSP authentication via CLI arguments, interactive masked prompts, or in-script configuration.</li>
  <li><strong>Controlled Password Masking:</strong> Automatically saves scan results to the current user's Desktop with passwords masked by default (showing only the first character).</li>
</ul>

<h3>Parameters</h3>
<table>
  <thead>
    <tr>
      <th>Parameter</th>
      <th>Default</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>-Subnet</code></td>
      <td><code>"192.168.1."</code></td>
      <td>Target <code>/24</code> subnet prefix (must end with a dot).</td>
    </tr>
    <tr>
      <td><code>-Credentials</code></td>
      <td><code>@()</code></td>
      <td>Comma-separated list of <code>"login:password"</code> pairs passed via CLI.</td>
    </tr>
    <tr>
      <td><code>-PromptCredentials</code></td>
      <td><code>$false</code></td>
      <td>Prompts for username and password interactively (input is hidden and excluded from shell history).</td>
    </tr>
    <tr>
      <td><code>-MaskPasswords</code></td>
      <td><code>$true</code></td>
      <td>Masks ~90% of password characters when saving the report file to Desktop.</td>
    </tr>
  </tbody>
</table>

<h3>Usage Examples</h3>
<p><strong>1. Default scan</strong> (uses subnet and credentials defined inside the script, masks passwords in report):</p>
<pre><code>.\scan-rtsp.ps1</code></pre>

<p><strong>2. Most secure method</strong> (interactive hidden password prompt, leaves no traces in command history or script file):</p>
<pre><code>.\scan-rtsp.ps1 -Subnet "192.168.0." -PromptCredentials</code></pre>

<p><strong>3. Pass one or multiple credentials via CLI:</strong></p>
<pre><code>.\scan-rtsp.ps1 -Subnet "192.168.0." -Credentials "admin:12345","user:qwerty"</code></pre>

<p><strong>4. Save report with unmasked (plain-text) passwords:</strong></p>
<pre><code>.\scan-rtsp.ps1 -Subnet "192.168.0." -MaskPasswords $false</code></pre>

<h3>Security &amp; Precautions</h3>
<ul>
  <li><strong>Authorized Networks Only:</strong> Use this diagnostic tool strictly on networks and devices you own or have explicit permission to audit.</li>
  <li><strong>Protect Your Credentials:</strong> Prefer <code>-PromptCredentials</code> over hardcoding passwords inside <code>$FileCredentials</code>. Always clear sensitive data before publishing.</li>
  <li><strong>Router Load:</strong> Keep <code>$MaxThreads</code> around <code>50</code> on home or small office routers to avoid connection drops.</li>
</ul>

<hr>

<h2>Русский</h2>

<h3>Описание и возможности</h3>
<p>Данный скрипт является <strong>инструментом сетевой диагностики и инвентаризации</strong>, предназначенным для администраторов и владельцев оборудования для поиска активных RTSP-источников и проверки доступности видеопотоков без установки стороннего ПО.</p>
<ul>
  <li><strong>Быстрое многопоточное сканирование:</strong> Использует PowerShell Runspaces для проверки подсети <code>/24</code> за несколько секунд.</li>
  <li><strong>Проверка протокола и путей:</strong> Сканирует популярные RTSP-порты (<code>554</code>, <code>8554</code> и др.) с помощью штатных запросов <code>OPTIONS</code> и <code>DESCRIBE</code>.</li>
  <li><strong>Гибкая и безопасная авторизация:</strong> Поддерживает Basic и Digest RTSP-аутентификацию через аргументы командной строки, интерактивный скрытый ввод или настройки внутри файла.</li>
  <li><strong>Управляемое скрытие паролей:</strong> Автоматически сохраняет отчёт на Рабочий стол текущего пользователя, маскируя пароли по умолчанию (остаётся только первый символ).</li>
</ul>

<h3>Параметры запуска</h3>
<table>
  <thead>
    <tr>
      <th>Параметр</th>
      <th>По умолчанию</th>
      <th>Описание</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>-Subnet</code></td>
      <td><code>"192.168.1."</code></td>
      <td>Префикс сканируемой подсети <code>/24</code> (обязательно с точкой на конце).</td>
    </tr>
    <tr>
      <td><code>-Credentials</code></td>
      <td><code>@()</code></td>
      <td>Список пар <code>"логин:пароль"</code> через запятую, передаваемый в строке запуска.</td>
    </tr>
    <tr>
      <td><code>-PromptCredentials</code></td>
      <td><code>$false</code></td>
      <td>Запрашивает логин и пароль интерактивно (ввод скрыт звёздочками и не попадает в историю команд).</td>
    </tr>
    <tr>
      <td><code>-MaskPasswords</code></td>
      <td><code>$true</code></td>
      <td>Скрывает ~90% пароля при сохранении файла отчёта на Рабочий стол.</td>
    </tr>
  </tbody>
</table>

<h3>Примеры запуска</h3>
<p><strong>1. Стандартный запуск</strong> (берёт настройки из скрипта, маскирует пароли в отчёте):</p>
<pre><code>.\scan-rtsp.ps1</code></pre>

<p><strong>2. Самый безопасный способ</strong> (интерактивный скрытый ввод пароля — не оставляет следов ни в файле, ни в истории PowerShell):</p>
<pre><code>.\scan-rtsp.ps1 -Subnet "192.168.0." -PromptCredentials</code></pre>

<p><strong>3. Передача одного или нескольких паролей прямо при запуске:</strong></p>
<pre><code>.\scan-rtsp.ps1 -Subnet "192.168.0." -Credentials "admin:12345","user:qwerty"</code></pre>

<p><strong>4. Сохранение отчёта с открытыми (незамаскированными) паролями:</strong></p>
<pre><code>.\scan-rtsp.ps1 -Subnet "192.168.0." -MaskPasswords $false</code></pre>

<h3>Меры безопасности и предосторожности</h3>
<ul>
  <li><strong>Только для своих сетей:</strong> Используйте этот диагностический инструмент исключительно в сетях и на устройствах, которыми вы владеете или имеете официальное разрешение на аудит.</li>
  <li><strong>Защита учётных данных:</strong> Используйте флаг <code>-PromptCredentials</code> вместо хранения паролей внутри массива <code>$FileCredentials</code>. Очищайте личные данные перед публикацией кода.</li>
  <li><strong>Нагрузка на сеть:</strong> Не выставляйте параметр <code>$MaxThreads</code> выше <code>50</code> на домашних роутерах, чтобы избежать сброса пакетов.</li>
</ul>

