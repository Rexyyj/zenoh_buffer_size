# Usage

## sub_rx_buffer.sh
It only varies the rx buffer size on subscriber.
"plot_sub.ipynb" is used to process its output.

## general_test.sh
This test script can be used to test varying tx and rx buffer.
Before using, a folder name "executables" should be created in the same directory. In side it should container folders named in numbers(batch numbers) which containing the entire "target" folder of zenoh build output.

For example:
./executables/8/target/
./executables/16/target/

Then we can run the script with:
```bash
sudo ./general_test.sh 8

sudo ./general_test.sh 16
# The output will be appended to the same log file
```
Then "plot_general.ipynb" can be used to process the output.

