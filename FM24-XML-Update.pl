use strict;
use warnings;
use Win32::GUI;
use File::Find;
use XML::LibXML;

my $directory   = 'D:\\Game\\Football Manager 2024\\graphics\\faces\\faces';
my $config_file = 'D:\\Game\\Football Manager 2024\\graphics\\faces\\faces\\config.xml';

# Create the main window
my $main_window = Win32::GUI::Window->new(
    -name   => 'MainWindow',
    -text   => 'FM 2024 Facepack XML Updater',
    -width  => 600,
    -height => 450,
    -background => [73, 29, 112],
    -onTerminate => sub { return -1; },
    -font => Win32::GUI::Font->new(
        -name => 'Segoe UI',
        -size => 10,
        -bold => 1,
    ),
);

# Center the window on the screen
my $screen_width  = Win32::GUI::GetSystemMetrics(0);
my $screen_height = Win32::GUI::GetSystemMetrics(1);
my $window_width  = 600;
my $window_height = 450;
my $x_pos = int(($screen_width - $window_width) / 2);
my $y_pos = int(($screen_height - $window_height) / 2);
$main_window->Move($x_pos, $y_pos);


# Add a button to process the XML
my $process_button = $main_window->AddButton(
    -name => 'ProcessButton',
    -text => 'Update config.xml',
    -left => 200,
    -top  => 20,
    -width => 200,
    -height => 40,
    -background => [89, 29, 143],
    -foreground => [255, 255, 255],
    -font => Win32::GUI::Font->new(
        -name => 'Segoe UI',
        -size => 10,
        -bold => 1,
    ),
);

# Add a button to select the directory
my $directory_button = $main_window->AddButton(
    -name => 'DirectoryButton',
    -text => '...',
    -left => 550,
    -top  => 80,
    -width => 20 ,
    -height => 20,
    -background => [89, 29, 143],
    -foreground => [255, 255, 255],
    -font => Win32::GUI::Font->new(
        -name => 'Segoe UI',
        -size => 10,
        -bold => 1,
    ),
    -onClick => \&SelectDirectory,
    
);

# Add a button to select the config file
my $config_button = $main_window->AddButton(
    -name => 'ConfigButton',
    -text => '...',
    -left => 550,
    -top  => 110,
    -width => 20,
    -height => 20,
    -background => [89, 29, 143],
    -foreground => [255, 255, 255],
    -font => Win32::GUI::Font->new(
        -name => 'Segoe UI',
        -size => 10,
        -bold => 1,
    ),
    -onClick => \&SelectConfigFile,
);


# Add a label to display the directory path
my $directory_label = $main_window->AddLabel(
    -name => 'DirectoryLabel',
    -text => "Directory: $directory",
    -left => 20,
    -top  => 80,
    -width => 500,
    -background => [116, 39, 181],
    -foreground => [0, 0, 0],
);

# Add a label to display the config file path
my $config_label = $main_window->AddLabel(
    -name => 'ConfigLabel',
    -text => "Config File: $config_file",
    -left => 20,
    -top  => 110,
    -width => 500,
    -background => [116, 39, 181],
    -foreground => [0, 0, 0],
);

# Add a label to watch the process
my $process_label = $main_window->AddLabel(
    -name => 'ProcessLabel',
    -text => 'Ready to process files.',
    -left => 20,
    -top  => 140,
    -width => 550,
    -background => [116, 39, 181],
    -foreground => [0, 0, 0],
);

# Add a label to display results
my $result_label = $main_window->AddLabel(
    -name => 'ResultLabel',
    -text => 'Result: ',
    -left => 20,
    -top  => 170,
    -width => 550,
    -background => [246, 156, 43],
    -foreground => [0, 0, 0],
);

# Event loop
$main_window->Show();
Win32::GUI::Dialog();

# Callback for selecting the directory
sub SelectDirectory {
    $directory = Win32::GUI::BrowseForFolder(
        -title => "Select Directory",
        -folder => $directory || "C:\\",
    );
    if ($directory) {
        $directory_label->Text("Directory: $directory");
    }
}

# Callback for selecting the config file
sub SelectConfigFile {
    $config_file = Win32::GUI::GetOpenFileName(
        -title => "Select Config File",
        -filter => ['XML Files' => '*.xml', 'All Files' => '*.*'],
        -directory => $directory || "C:\\",
    );
    if ($config_file) {
        $config_label->Text("Config File: $config_file");
    }
}


# Callback for the button click
sub ProcessButton_Click {
    $process_label->Text('Processing... Please wait.');
    # Parse the existing config.xml file
    my $parser = XML::LibXML->new();
    my $doc;

    if (-e $config_file) {
        $doc = $parser->parse_file($config_file);
    } else {
        $result_label->Text("Error: Config file not found.");
        return;
    }

    my $root = $doc->documentElement;

    # Get all the "from" attributes in the config file
    my %existing_records = map {
        $_->getAttribute('from') => 1
    } $root->findnodes('//record');

    # Traverse the directory for .png files
    opendir(my $dh, $directory) or die "Cannot open directory $directory: $!";
    my @png_files = grep { /\.png$/i } readdir($dh);
    closedir($dh);

    # Add missing records to the XML document
    my $modified = 0;

    foreach my $file (@png_files) {
        my ($file_base) = $file =~ /^(\d+)\.png$/; # Extract file number (e.g., 20020446456 from 20020446456.png)
        next unless defined $file_base;           # Skip files that don't match the pattern

        if (!exists $existing_records{$file_base}) {
            # Ensure <list> node exists
            my $list_node = ($root->findnodes('//list'))[0];
            if (!$list_node) {
                $list_node = $doc->createElement('list');
                $root->appendChild($list_node);
            }

            # Add a new <record> element
            my $new_record = $doc->createElement('record');
            $new_record->setAttribute('from', $file_base);
            $new_record->setAttribute('to', "graphics/pictures/person/$file_base/portrait");
            $list_node->appendChild($new_record);

            $modified = 1;
            $process_label->Text("Processing... $file_base.png");
            print "Added record for $file_base\n";
        }
    }

    # Sort records inside the <list> node
    if ($modified) {
        my $list_node = ($root->findnodes('//list'))[0];
        if ($list_node) {
            # Collect all <record> nodes
            my @records = $list_node->findnodes('./record');

            # Sort by the "from" attribute numerically
            @records = sort {
                $a->getAttribute('from') <=> $b->getAttribute('from')
            } @records;

            # Remove all existing <record> nodes from <list>
            $list_node->removeChildNodes();

            # Append sorted <record> nodes back to <list>
            foreach my $record (@records) {
                $list_node->appendChild($record);
            }
        }
    }

    # Format the XML with newlines and tabs for better readability
    if ($modified) {
        my $list_node = ($root->findnodes('//list'))[0];
        if ($list_node) {
            foreach my $record ($list_node->findnodes('./record')) {
                $record->unbindNode();
                $list_node->appendText("\n\t");
                $list_node->appendChild($record);
            }
            $list_node->appendText("\n");
        }
    }

    # Save the modified config file if changes were made
    if ($modified) {
        open my $fh, '>:encoding(UTF-8)', $config_file or die "Cannot open $config_file for writing: $!";
        print $fh $doc->toString(1); # Pretty print with indentation
        close $fh;
        $process_label->Text('Processing... Done.');
        $result_label->Text("Config file updated and sorted.");
    } else {
        $process_label->Text('Processing... Done');
        $result_label->Text("No changes were made. All PNG files are already listed.");
    }
}
