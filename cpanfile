requires 'Log::Minimal',  0.14;
requires 'File::Stamped', 0.03;

on 'test' => sub {
    requires 'Test::Output', 1.01;
};
