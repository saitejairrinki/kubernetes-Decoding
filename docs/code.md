# Code Example

### PHP

```php
class App {

  /**
  * @var string
  */
  private $name;

  public __construct($name)
  {
    $this->name = $name;
  }
}
```

### C#

```csharp
public class App {

  private string Name {get; set;}

  public App(string name)
  {
    this.Name = name;
  }
}
```

### Json 

```json
{"result":"success"}
```

### Bash

```bash
curl -H 'Content-type: application/json' http://localhost:8080/api/

```

```bash
vi /etc/resolvconf/resolv.conf.d/head

```


=== "C"

    ``` c
    #include <stdio.h>

    int main(void) {
      printf("Hello world!\n");
      return 0;
    }
    ```

=== "C++"

    ``` c++
    #include <iostream>

    int main(void) {
      std::cout << "Hello world!" << std::endl;
      return 0;
    }
    ```

