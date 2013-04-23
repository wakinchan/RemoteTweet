#!/bin/sh
expect -c"
spawn make package install
expect {
  \"'s password:\" {
    send \"alpine\r\"
    expect \"'s password:\"
    send \"alpine\r\"
	expect \"'s password:\"
    send \"alpine\r\"
  }
}
interact
"
