#!/usr/bin/perl -w
use strict;

use Term::ReadKey;
use Term::ANSIColor;

my $global_x;
my $global_y;

my @cpus;
my ($prev_idle, $prev_total) = qw(0 0);
sub get_cpu ($$$$) {

    my $disp = shift;
    my $addr_r = shift;
    my $port_r = shift;

    
    my @proc = split/\s+/,$_;

    shift @proc;
    my $idle = $proc[3];
    my $total = $proc[0]+$proc[1]+$proc[2]+$proc[3]+$proc[4]+$proc[5]+$proc[6];
    my $diff_idle = $idle - $prev_idle;
    my $diff_total = $total - $prev_total;
    my $diff_usage = 100*($diff_total - $diff_idle)/$diff_total;
    
    $prev_idle = $idle;
    $prev_total = $total;

        
    push @cpus, $diff_usage;
       

    my ($wchar, $hchar) = GetTerminalSize();
    $global_y = $wchar - 28;
    $global_y = 0 if $global_y < 0;
    $global_x = $hchar - 6;
    $global_x = 0 if $global_x < 0;
    while (@cpus+0 >= $global_y+2) {shift @cpus;}
    matrix(@cpus);      
    # The matrix() is processing every single second,
    # while the print_matrix() is executed only when 
    # the certain process gets a special signal which make $disp = 1
    print_matrix($addr_r,$port_r,@cpus) if $disp == 1;

}

my $matrix;
sub matrix {

    $matrix = ();

    # Two additional values: zero and $global_x+1 are needed for printing borders
    foreach my $row (0..$global_x+1) {
        foreach my $column (0..$global_y+1) {
            $matrix->[$row][$column] = " ";
        }
    }   
 
    $matrix->[0][0] = "┌";
    $matrix->[0][$global_y+1] = "┐";
    $matrix->[$global_x+1][0]= "└";
    $matrix->[$global_x+1][$global_y+1] = "┘";    

    foreach my $column (1..$global_y) {
        $matrix->[0][$column] = "─";    
        $matrix->[$global_x+1][$column] = "─";
    }

    foreach my $row (1..$global_x) {
        $matrix->[$row][0] = "│";
        $matrix->[$row][$global_y+1] = "│";
    }


    # shift @_ here always removes the very first element of @cpus
    # which was counted falsely, so we do not need this value.
    shift @_;
    for (my $i=0; $i<(@_+0); $i++) {
        for (my $j=0; $j<=($_[@_-1-$i]*$global_x/100)-1; $j++) {
            $matrix->[$global_x-$j][$global_y-$i] = "█";
        }
    }
}

sub print_matrix {

    my $addr_r = shift;
    my $port_r = shift;    
    
    # The same shift @_ should be executed here as far as the current function 
    # gets only a reference to an array @cpus so it is untouched by matrix(). 
    shift @_;    


    my $average;
    for (my $i=0; $i<@_+0; $i++) {
        $average+=$_[$i];
    }
    $average/=(@_+0) if (@_+0)>0;

    print "\033[2J";
    


    print "\n";

    # The counter for things placed near the @$matrix.
    my $k=1;
    # Everything is bold blue here
    # Could be elaborated with more exquisite coloring
    # But that is not a point
    print color 'bold blue';
    foreach my $row (@$matrix) {
        print "    ";
        foreach my $elem (@$row) {
       
            print $elem;
        }
        if ($k == @$matrix+0 - 9) {
            print "  Press \"n/N\" for";
        }
        elsif ($k == @$matrix+0 - 8) {
            print "  (N)ext connection";
        }
        elsif ($k == @$matrix+0 - 5) {
            print "  $addr_r:$port_r";
        }
        elsif ($k == @$matrix+0 -6) {
            print "  pid = $$";
        }
        elsif ($k == @$matrix+0 -4) {
            print "  %avr: ";
            if (defined $average) {printf ("%5.2f",$average);}
            else {print "     ";}

            print " (",@_+0,"s.)";
        }
        elsif ($k == @$matrix+0 -2) {
            print "  %cpu: ";
            printf ("%5.2f",$_[-1]) if defined $_[-1];
        }
        $k++;
        
        print "\n";
    }
    print "\n";
}


### socket stuff >>>
use Socket;

my $port = shift @ARGV || 12321;

socket (my $server, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or die "socket: $!\n";

my $packed_addr = sockaddr_in ($port, INADDR_ANY) or die "sockaddr_in $!\n";

bind ($server, $packed_addr) or die "bind $!\n";

listen ($server, SOMAXCONN) or die "listen: $!\n";
### <<< socket stuff





# These SIGs instructions would be executed only if be called up before the main process forks.
# And it forks only after it gets at least one client connection.
# After it forks it gets the new instructions for SIDUSR1.
$SIG{'USR1'}= sub {    # Why do you want to press (N)ext if there is no one here?
                       print "NO CONNECTIONS RUNNING\n";
                  };

# The DISPATCHER is listening for your input and switches processes if you press n/N.

my $father = $$;
my $pdisp = fork;
# The DISPATCHER is to be a CHILD process. Thus, if it dies for some reason 
# (like pressing some key on the keyboard which is way too unbearable for understanding)
# the main program will continue it's execution, available for ^C to killing it. 
if ($pdisp == 0) {
    ReadMode('cbreak');
    while (1) {
        my $char = ReadKey(0);
        if (($char eq "n")or($char eq "N")) {
            kill 'USR1', $father;
        }
    }
}

# All childs(clients) are to be placed in @pids.
my @pids;
# The number of how many times the process gets SIGUSR1.
# We are using $to_print to printing NEXT process, makint it $to_print++ after each SIG.
# As the first process (zero element in @pids) prints itself automatically,
# the next process number to print is 1.
my $to_print=1;
# Without while(1) process dies when gets a signal as it doesn't approve it accept function.
while (1) {
    while (my $mega_addr = accept(my $client, $server)) {

        my $new_pid = fork;
        if ($new_pid != 0) {

            $SIG{'USR1'}= sub {
                                   kill 'USR1', @pids;
                                   # $to_print is the number of an array we want send the signal to
                                   # It can not be equal e.g. 4 in 4 elements array
                                   $to_print = 0 if $to_print==@pids+0;
                                   kill 'USR2', $pids[$to_print];
                                   $to_print++;
                              };
            push @pids, $new_pid;
        }

        else {
            
            my $disp = 0;
            
            my ($port_r, $mini_r) = sockaddr_in ($mega_addr);
            my $addr_r = inet_ntoa ($mini_r);

            # USR1 and USR2 are about to not display or to do display the process respectively
            $SIG{'USR1'} = sub {$disp=0;};
            $SIG{'USR2'} = sub {$disp=1; print_matrix($addr_r, $port_r, @cpus);};
            # If there were no connections on server, the first connected are automaticaly displayed, no sigs needed.
            if (($pids[0] == $$) or (not defined $pids[0])) {$disp=1; print_matrix($addr_r, $port_r, @cpus);}
            
            # Sometimes you are pressing (N)ext far too more often than the client send his info.
            # So we captured the while (<$client>) loop in the even more unbreakable loop while (1).
            while (1) {
                while (<$client>) {         
                    get_cpu($disp,$addr_r,$port_r,$_);
                }
                # If connection is lost, the sleep line will save the server 
                # from 100% cpu load while looping (1).
                # Dead connections are processing with the one time print_matrix
                # right after they get 'USR2' signal.
                sleep 1;
            }
        }
    }
}
